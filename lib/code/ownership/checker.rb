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
          @git = Git.open(repo, log: Logger.new(IO::NULL))
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
          errors = { missing_ref: [], useless_pattern: [] }
          added_files.each do |file|
            next if defined_owner?(file)

            errors[:missing_ref] << file
          end

          ownership.each do |row|
            next if pattern_has_files(row.pattern)

            errors[:useless_pattern] << row
          end
          errors
        end

        def pattern_has_files(pattern)
          @git.ls_files(pattern).any?
        end

        def defined_owner?(file)
          ownership.find do |row|
            row.regex.match file
          end
        end

        Ownership = Struct.new(:pattern, :regex, :owners)
        def ownership
          @ownership ||= @git
                         .gblob("#{@to}:.github/CODEOWNERS")
                         .contents.lines.map(&:chomp)
                         .reject { |line| line.nil? || line.match?(/^\s*#|^$/) }
                         .map do |line|
            head, *tail = line.split(/\s+/)
            regex = pattern_to_regex(head)
            Ownership.new head, regex, tail
          end
        end

        def pattern_to_regex(str)
          regex = str.gsub(%r{/\*\*}, '(/[^/]+)+').gsub(/\*/, '[^/]+')
          Regexp.new(regex)
        end
      end
    end
  end
end
