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

      class Ownership < Struct.new(:pattern, :owners, :line, :comments)
        def regex
          Regexp.new(pattern.gsub(%r{/\*\*}, '(/[^/]+)+').gsub(/\*/, '[^/]+'))
        end

        def to_s
          [pattern, owners].join ' '
        end
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

        def codeowners_raw_content
          codeowners_file.contents.lines
        end

        def codeowners_file
          @git.gblob("#{@to}:.github/CODEOWNERS")
        end

        def ownership
          CodeOwnersFile.new(codeowners_raw_content).parse!
        end
      end

      # Parse .github/CODEOWNERS into Ownership that is a
      # Struct.new(:pattern, :regex, :owners, :line, :comments)
      # It parses and attach previous comments to the content
      # to allow us to rewrite the file in the future.
      class CodeOwnersFile
        def initialize content
          @content = content
          @owners = []
          @comments = []
        end

        def parse!
          @content.each_with_index do |line, i|
            next if line.nil?
            if line.match?(/^\s*#|^$/)
               @comments << line
               next
            end
            @line_number = i + 1
            process_ownership line
          end
          @owners
        end

        def process_ownership line
          pattern, *owners = line.chomp.split(/\s+/)
          @owners << Ownership.new(pattern, owners, @line_number, @comments)
          @comments = []
        end
      end
    end
  end
end
