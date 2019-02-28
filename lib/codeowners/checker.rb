# frozen_string_literal: true

require 'git'
require 'logger'

require_relative 'checker/code_owners'
require_relative 'checker/file_as_array'
require_relative 'checker/group'

module Codeowners
  # Check if code owners are consistent between a git repository and the CODEOWNERS file.
  # It compares what's being changed in the PR and check if the current files and folders
  # are also being declared in the CODEOWNERS file.
  class Checker
    attr_accessor :when_useless_pattern, :when_new_file

    # Get repo metadata and compare with the owners
    def initialize(repo, from, to)
      @git = Git.open(repo, log: Logger.new(IO::NULL))
      @repo_dir = repo
      @from = from || 'HEAD'
      @to = to
    end

    def transformers
      @transformers ||= []
    end

    def changes_to_analyze
      @git.diff(@from, @to).name_status
    end

    def added_files
      changes_to_analyze.select { |_k, v| v == 'A' }.keys
    end

    def check!
      {
        missing_ref: missing_reference,
        useless_pattern: useless_pattern
      }
    end

    def changes_for_patterns(patterns)
      @git.diff(@from, @to).path(patterns).name_status.keys
    end

    def patterns_by_owner
      @patterns_by_owner ||=
        codeowners.each_with_object(hash_of_arrays) do |line, patterns_by_owner|
          next unless line.pattern?

          line.owners.each { |owner| patterns_by_owner[owner] << line.pattern }
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

    def useless_pattern
      codeowners.select do |line|
        next unless line.pattern?

        unless pattern_has_files(line.pattern)
          @when_useless_pattern&.call(line)
          true
        end
      end
    end

    def missing_reference
      added_files.reject(&method(:defined_owner?))
    end

    def pattern_has_files(pattern)
      @git.ls_files(pattern).any?
    end

    def defined_owner?(file)
      codeowners.find do |line|
        next unless line.pattern?

        return true if line.match_file?(file)
      end

      @when_new_file&.call(file) if @when_new_file
      false
    end

    def codeowners
      @codeowners ||= CodeOwners.new(
        FileAsArray.new(codeowners_filename),
        transformers: transformers
      )
    end

    def main_group
      codeowners.main_group
    end

    def commit_changes!
      @git.add(codeowners_filename)
      @git.commit('Fix pattern :robot:')
    end

    private

    def codeowners_filename
      directories = ['', '.github', 'docs', '.gitlab']
      paths = directories.map { |dir| File.join(@repo_dir, dir, 'CODEOWNERS') }
      Dir.glob(paths).first || paths.first
    end
  end
end
