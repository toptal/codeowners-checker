# frozen_string_literal: true

require 'code/ownership/checker/version'
require 'git'
require 'logger'

module Code
  module Ownership
    module Checker
      module_function

      def check!(repo, from, to)
        GitChecker.new(repo, from, to).check!
      end
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
            next if have_ownership?(file)

            errors << "Missing #{file} to add to .github/CODEOWNERS"
          end
          { errors: errors }
        end

        def have_ownership?(file)
          owners.find do |pattern, _owner|
            pattern
              .gsub(/\*\*/, '(/[^/]+)+')
              .gsub(/\*/, '/[^/]+')

            Regexp.new(pattern).match file
          end
        end

        def owners
          @git
            .gblob('master:.github/CODEOWNERS')
            .contents.lines.map(&:chomp)
            .map { |line| line.split(/\s+/) }
        end
      end
    end
  end
end
