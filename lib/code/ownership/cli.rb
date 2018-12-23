# frozen_string_literal: true

require 'thor'
require 'fuzzy_match'
require_relative 'checker'

# frozen_string_literal: true
module Code
  module Ownership
    # Command Line Interface used by bin/code-owners-checker.
    class CLI < Thor
      LABEL = { missing_ref: 'Missing references', useless_pattern: 'No files matching with the pattern' }.freeze
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true,  type: :boolean, aliases: '-i'
      desc 'check consistency', 'checks .github/CODEOWNERS consistency'
      def check(repo = '.')
        @repo = repo
        @checker = Code::Ownership::Checker.new(@repo, options[:from], options[:to])
        @checker.when_useless_pattern do |record|
          suggest_fix_for record
        end
        @checker.check!
        @checker.commit_changes! if yes?('Commit changes?')
      end

      private

      def suggest_fix_for(record)
        pattern = record.pattern
        search = FuzzyMatch.new(files_from(pattern))
        suggestion = search.find(pattern)
        apply_suggestion(record, suggestion) if suggestion
      end

      def apply_suggestion(record, suggestion)
        return unless yes?("Pattern #{record.pattern} doesn't match. Replace with: #{suggestion}?")

        @checker.codeowners_file.update line: record.line, pattern: suggestion
        File.open(@repo + Code::Ownership::Checker::FILE_LOCATION, 'w+') do |f|
          f.puts @checker.codeowners_file.process_content!
        end
      end

      def files_from(pattern)
        parent_pattern = pattern.split('/')[0..-2].join('/')
        Dir[@repo + parent_pattern + '/*'].map { |f| f.gsub(@repo, '') }
      end
    end
  end
end
