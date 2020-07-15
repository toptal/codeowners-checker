# frozen_string_literal: true

require 'git'
require 'logger'

require_relative 'checker/code_owners'
require_relative 'checker/file_as_array'
require_relative 'checker/group'
require_relative 'checker/owners_list'
require_relative 'checker/whitelist'

module Codeowners
  # Check if code owners are consistent between a git repository and the CODEOWNERS file.
  # It compares what's being changed in the PR and check if the current files and folders
  # are also being declared in the CODEOWNERS file.
  # By default (:validate_owners property) it also reads OWNERS with list of all
  # possible/valid owners and validates every owner in CODEOWNERS is defined in OWNERS
  class Checker
    attr_reader :owners_list, :enabled_checks

    ALL_CHECKS = %i[missing_ref useless_pattern invalid_owner unrecognized_line].freeze

    # Get repo metadata and compare with the owners
    def initialize(repo:, from:, to:, checks: ALL_CHECKS)
      @git = Git.open(repo, log: Logger.new(IO::NULL))
      @repo_dir = repo
      @from = from || 'HEAD'
      @to = to
      @owners_list = OwnersList.new(@repo_dir)
      @enabled_checks = checks
    end

    def changes_to_analyze
      @git.diff(@from, @to).name_status.reject(&whitelist)
    end

    def added_files
      changes_to_analyze.select { |_k, v| v == 'A' }.keys
    end

    def fix!
      Enumerator.new { |yielder| catch(:user_quit) { results.each { |r| yielder << r } } }
    end

    def changes_for_patterns(patterns)
      @git.diff(@from, @to).path(patterns).name_status.keys.reject(&whitelist)
    end

    def patterns_by_owner
      @patterns_by_owner ||=
        codeowners.each_with_object(hash_of_arrays) do |line, patterns_by_owner|
          next unless line.pattern?

          line.owners.each { |owner| patterns_by_owner[owner] << line.pattern.gsub(%r{^/}, '') }
        end
    end

    def hash_of_arrays
      Hash.new { |h, k| h[k] = [] }
    end

    def changes_with_ownership(owner = '')
      patterns_by_owner.each_with_object({}) do |(own, patterns), changes_with_owners|
        next if (owner != '') && (own != owner)

        changes_with_owners[own] = changes_for_patterns(patterns)
      end
    end

    def list_files_for_owner(owner = '')
      patterns = patterns_by_owner[owner]
      patterns.each_with_object({}) do |pattern, results|
        results[pattern] = files_for_pattern(pattern).map(&:first)
      end
    end

    def useless_pattern
      @useless_pattern ||= codeowners.select do |line|
        line.pattern? && !pattern_has_files(line.pattern)
      end
    end

    def missing_reference
      @missing_reference ||= added_files.reject(&method(:defined_owner?))
    end

    def files_for_pattern(pattern)
      @git.ls_files(pattern.gsub(%r{^/}, '')).reject(&whitelist)
    end

    def pattern_has_files(pattern)
      files_for_pattern(pattern).any?
    end

    def defined_owner?(file)
      codeowners.find do |line|
        next unless line.pattern?

        return true if line.match_file?(file)
      end

      false
    end

    def whitelist?
      whitelist.exist?
    end

    def whitelist_filename
      @whitelist_filename ||= CodeOwners.filename(@repo_dir) + '_WHITELIST'
    end

    def whitelist
      @whitelist ||= Whitelist.new(whitelist_filename)
    end

    def codeowners
      @codeowners ||= CodeOwners.new(
        FileAsArray.new(CodeOwners.filename(@repo_dir))
      )
    end

    def main_group
      codeowners.main_group
    end

    def consistent?
      results.none?
    end

    def commit_changes!
      @git.add(File.realpath(@codeowners.filename))
      @git.add(File.realpath(@owners_list.filename))
      @git.commit('Fix pattern :robot:')
    end

    def unrecognized_line
      @unrecognized_line ||= codeowners.select do |line|
        line.is_a?(Codeowners::Checker::Group::UnrecognizedLine)
      end.reject(&whitelist)
    end

    private

    def invalid_owners
      @invalid_owners ||= @owners_list.invalid_owners(codeowners)
    end

    def results
      @results ||= Enumerator.new do |yielder|
        enabled_checks.each do |check|
          check_results(check).each { |result| yielder << result }
        end
      end
    end

    def check_results(check)
      case check
      when :missing_ref
        missing_reference.map { |ref| [:missing_ref, ref] }
      when :useless_pattern
        useless_pattern.map { |pattern| [:useless_pattern, pattern] }
      when :invalid_owner
        invalid_owners.map { |(owner, missing)| [:invalid_owner, owner, missing] }
      when :unrecognized_line
        unrecognized_line.map { |line| [:unrecognized_line, line] }
      end
    end
  end
end
