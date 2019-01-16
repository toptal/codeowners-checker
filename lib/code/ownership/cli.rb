# frozen_string_literal: true

require 'thor'
require 'fuzzy_match'
require_relative 'checker'
require_relative 'filter'
require_relative 'cli_base'

# frozen_string_literal: true
module Code
  module Ownership
    # Command Line Interface used by bin/code-owners-checker.
    class CLI < CLIBase
      LABEL = { missing_ref: 'Missing references', useless_pattern: 'No files matching with the pattern' }.freeze
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true, type: :boolean, aliases: '-i'
      desc 'check REPO', 'Checks .github/CODEOWNERS consistency'
      def check(repo = '.')
        @repo = repo
        setup_checker
        @checker.check!
        @checker.commit_changes! if options[:interactive] && yes?('Commit changes?')
      end

      desc 'filter <by-owner>', 'List owners of changed files'
      subcommand 'filter', Code::Ownership::Filter

      desc 'config', 'Checks config is consistent or configure it'
      option :team
      def config
        return unless validate_team_file && validate_team_options

        save_team if options[:team]
        puts "default team: #{default_team}"
      end

      private

      def setup_checker
        @checker = Code::Ownership::Checker.new(@repo, options[:from], options[:to])
        @checker.when_useless_pattern = lambda do |record|
          suggest_fix_for record
        end

        @checker.when_new_file = lambda do |file|
          suggest_add_to_codeowners file
        end
      end

      def save_team
        team_name = '@toptal/' + options[:team]
        File.open(default_team_file, 'w+') { |file| file.puts team_name }
      end

      def validate_team_options
        return true unless options[:team]

        return banner_how_to_config_team if options[:team] == 'team'

        true
      end

      def write_codeowners_file
        File.open(@repo + '/' + Code::Ownership::Checker::FILE_LOCATION, 'w+') do |f|
          f.puts @checker.codeowners_file.process_content!.join("\n")
        end
        # We need to reparse the file after changes have been made,
        # to make sure the line numbers are correct
        @checker.codeowners_file.parse!
      end

      def suggest_add_to_codeowners(file)
        return unless yes?("File added: #{file}. Add owner to CODEOWNERS?")

        owner = ask('File owner(s): ')

        return if owner.nil? || owner.empty?

        @checker.codeowners_file.append pattern: file, owners: owner
        write_codeowners_file
      end

      def suggest_fix_for(record)
        pattern = record.pattern
        search = FuzzyMatch.new(files_from(pattern))
        suggestion = search.find(pattern)
        apply_suggestion(record, suggestion) if suggestion
      end

      def make_suggestion(record, suggestion)
        ask(<<~QUESTION, limited_to: %w[y i d])
          Pattern #{record.pattern} doesn't match.
          Replace with: #{suggestion}?
          (y) to apply the suggestion
          (i) to ignore
          (d) to delete the pattern
        QUESTION
      end

      def apply_suggestion(record, suggestion)
        case make_suggestion(record, suggestion)
        when 'i' then return
        when 'y'
          @checker.codeowners_file.update line: record.line, pattern: suggestion
        when 'd'
          @checker.codeowners_file.delete line: record.line
        end
        write_codeowners_file
      end

      def files_from(pattern)
        parent_pattern = pattern.split('/')[0..-2].join('/')
        Dir[@repo + parent_pattern + '/*'].map { |f| f.gsub(@repo, '') }
      end
    end
  end
end
