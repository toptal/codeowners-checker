# frozen_string_literal: true

require 'code/ownership/checker/version'
require 'code/ownership/record'
require 'code/ownership/code_owners_file'
require 'git'
require 'logger'

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

      FILE_LOCATION = '.github/CODEOWNERS'

      # Get repo metadata and compare with the owners
      def initialize(repo, from, to)
        @git = Git.open(repo, log: Logger.new(IO::NULL))
        @repo_dir = repo
        @from = from
        @to = to
      end

      def changes_to_analyze
        @git.diff(master, my_changes).name_status
      end

      def added_files
        changes_to_analyze.select { |_k, v| v == 'A' }.keys
      end

      def deleted_files
        changes_to_analyze.select { |_k, v| v == 'D' }.keys
      end

      def changed_files
        changes_to_analyze.keys
      end

      def master
        @git.object(@from)
      end

      def my_changes
        @git.object(@to)
      end

      def check!
        @ownership ||= codeowners_file.parse!
        check_deleted_files
        {
          missing_ref: missing_reference,
          useless_pattern: useless_pattern
        }
      end

      def changes_for_patterns(patterns)
        @git.diff(master, my_changes).path(patterns).name_status.keys
      end

      def patterns_by_owner
        unless @patterns_by_owner
          @patterns_by_owner = {}
          ownership.each do |rec|
            rec.owners.each { |owner| patterns_by_owner[owner] = (patterns_by_owner[owner] || []) << rec.pattern }
          end
        end
        @patterns_by_owner
      end

      def changes_with_ownership(owner = '')
        changes_with_owners = {}
        patterns_by_owner.keys
                         .select { |o| o == owner || owner == '' }
                         .each { |own| changes_with_owners[own] = changes_for_patterns(patterns_by_owner[own]) }
        changes_with_owners
      end

      def useless_pattern
        ownership.select do |row|
          unless pattern_has_files(row.pattern)
            @when_useless_pattern&.call(row)
            true
          end
        end
      end

      def check_deleted_files
        return unless @when_deleted_file

        deleted_files.each { |file| @when_deleted_file&.call(file) }
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

      def codeowners_raw_content
        codeowners_from_git.contents.lines
      end

      def codeowners_from_git
        @git.gblob("#{@to}:#{FILE_LOCATION}")
      end

      def codeowners_file
        @codeowners_file ||= CodeOwnersFile.new(codeowners_raw_content)
      end

      def when_useless_pattern(&block)
        @when_useless_pattern = block
      end

      def when_new_file(&block)
        @when_new_file = block
      end

      def when_deleted_file(&block)
        @when_deleted_file = block
      end

      def ownership
        @ownership ||= codeowners_file.parse!
      end

      def commit_changes!
        @git.add(FILE_LOCATION)
        @git.commit('Fix pattern :robot:')
      end
    end
  end
end
