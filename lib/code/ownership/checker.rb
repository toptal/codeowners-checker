# frozen_string_literal: true

require 'git'
require 'logger'

require 'code/ownership/checker/version'
require 'code/ownership/checker/code_owners'
require 'code/ownership/checker/file_as_array'
require 'code/ownership/config'

module Code
  module Ownership
    # Check code ownership is consistent between a git repository and
    # .github/CODEOWNERS file.
    # It can compare different what's being changed in the PR and check
    # if the current files and folders are also being declared in the CODEOWNERS file.
    class Checker
      # Check some repo from a reference to another
      def self.check!(repo, from, to)
        new(repo, from, to).check!
      end

      attr_accessor :when_useless_pattern, :when_new_file

      # Get repo metadata and compare with the owners
      def initialize(repo, from, to)
        @git = Git.open(repo, log: Logger.new(IO::NULL))
        @repo_dir = repo
        @from = from || 'HEAD'
        @to = to
      end

      def changes_to_analyze
        @git.diff(@from, @to).name_status
      end

      def added_files
        changes_to_analyze.select { |_k, v| v == 'A' }.keys
      end

      def changed_files
        changes_to_analyze.keys
      end

      def check!
        @ownership ||= codeowners.parse!
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
          ownership.each_with_object(hash_of_arrays) do |rec, patterns_by_owner|
            rec.owners.each { |owner| patterns_by_owner[owner] << rec.pattern }
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
        ownership.select do |row|
          unless pattern_has_files(row.pattern)
            @when_useless_pattern&.call(row)
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
        if ownership.find { |row| row.regex.match file }
          true
        else
          @when_new_file&.call(file) if @when_new_file
          false
        end
      end

      def codeowners
        @codeowners ||= CodeOwners.new(
          FileAsArray.new(codeowners_file)
        )
      end

      def codeowners_file
        File.join(@repo_dir, '.github', 'CODEOWNERS')
      end

      def ownership
        @ownership ||= codeowners.parse!
      end

      def commit_changes!
        @git.add(codeowners_file)
        @git.commit('Fix pattern :robot:')
      end
    end
  end
end
