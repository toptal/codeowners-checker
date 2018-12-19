# frozen_string_literal: true

require 'code/ownership/checker/version'
require 'git'
require 'logger'

module Code
  module Ownership
    # Check code ownership is consistent between a git repository and
    # .github/CODEOWNERS file.
    # It can compare different what's being changed in the PR and check
    # if the current files and folders are also being declared in the CODEOWNERS file.
    module Checker
      module_function

      # Check some repo from a reference to another
      def check!(repo, from, to)
        GitChecker.new(repo, from, to).check!
      end

      # Get repo metadata and compare with the owners
      class GitChecker
        def initialize(repo, from, to)
          @git = Git.open(repo, log: Logger.new(STDOUT))
          @from = from
          @to = to
        end

        def changes_to_analyze
          @git.diff(master, my_changes).name_status
        end

        def added_files
          changes_to_analyze.select { |_k, v| v == 'A' }.keys
        end

        def master
          @git.object(@from)
        end

        def my_changes
          @git.object(@to)
        end

        def check!
          errors = []
          added_files.each do |file|
            next if defined_owner?(file)

            errors << "Missing #{file} to add to .github/CODEOWNERS"
          end

          owners.each do |pattern, _|
            next if pattern_has_files(pattern)

            errors << "No files matching pattern #{pattern} in .github/CODEOWNERS"
          end
          { errors: errors }
        end

        def pattern_has_files(pattern)
          @git.ls_files(pattern).any?
        end

        def defined_owner?(file)
          owners.find do |pattern, _owner|
            if !pattern then 
              return false 
            end
            pattern
              .gsub(/\*\*/, '(/[^/]+)+')
              .gsub(/\*/, '/[^/]+')

            Regexp.new(pattern).match file
          end
        end

        def owners
          @git
            .gblob("#{@to}:.github/CODEOWNERS")
            .contents.lines.map(&:chomp)
            .reject { |line| line.blank? || line.match?(/^\s*#/)
            .map { |line| line.split(/\s+/) }
        end
      end
    end
  end
end
