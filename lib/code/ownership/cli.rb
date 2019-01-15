# frozen_string_literal: true

require 'thor'
require 'fuzzy_match'
require_relative 'checker'

# frozen_string_literal: true
module Code
  module Ownership
    class ChangesByOwner < Thor
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :verbose, default: false, type: :boolean, aliases: '-v'
      desc 'by_team [TEAM]', 'Lists changed files owned by TEAM. If no team is specified, default team is taken from .default_team'
      # option :local, default: false, type: :boolean, aliases: '-l'
      # option :branch, default: '', aliases: '-b'
      def by_team(team_name = nil)
        team_name ||= default_team

        unless team_name
          puts 'Please provide a team name or configure a default team.',
          "Try `#{$PROGRAM_NAME} --team <team-name>` to configure the team."
          return
        end

        changes = checker.changes_with_ownership(team_name)
        if changes.key?(team_name)
          changes.values.each { |file| puts file }
        else
          puts "Owner #{team_name} not defined in .github/CODEOWNERS"
        end
      end

      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :verbose, default: false, type: :boolean, aliases: '-v'
      desc 'by_team USER', 'Lists changed files owned by USER'
      def by_user(user)
        checker.changes_with_ownership { |rec| rec.owners.find { |owner| owner == '@' + user } }.each do |rec|
          puts rec.owner + ":\n  " + rec.changes.join("\n  ") + "\n\n"
        end
      end

      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :verbose, default: false, type: :boolean, aliases: '-v'
      desc 'all', 'Lists all changed files grouped by owner'
      def all
        changes = checker.changes_with_ownership.select { |_owner, val| val && !val.empty? }
        changes.keys.each do |owner|
          puts(owner + ":\n  " + changes[owner].join("\n  ") + "\n\n")
        end
      end

      def initialize(args = [], options = {}, config = {})
        super
        @repo_base_path = `git rev-parse --show-toplevel`
        @default_team_file = @repo_base_path.chomp + '/.default_team'
        if !@repo_base_path || @repo_base_path.empty?
          raise 'You must be positioned in a git repository to use this tool'
        end

        @repo_base_path.chomp!
        Dir.chdir(@repo_base_path)
      end

      private

      def checker
        @checker ||= Code::Ownership::Checker.new(@repo_base_path, options[:from], options[:to])
      end

      def default_team
        return unless File.exist?(@default_team_file)

        IO.read(@default_team_file).chomp
      end
    end

    # Command Line Interface used by bin/code-owners-checker.
    class CLI < Thor
      attr_reader :default_team_file
      def initialize(*args)
        super
        @repo_base_path = `git rev-parse --show-toplevel`.chomp
        @default_team_file = @repo_base_path + '/.default_team'
      end

      LABEL = { missing_ref: 'Missing references', useless_pattern: 'No files matching with the pattern' }.freeze
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true, type: :boolean, aliases: '-i'
      desc 'check REPO', 'Checks .github/CODEOWNERS consistency'
      def check(repo = '.')
        @repo = repo
        @checker = Code::Ownership::Checker.new(@repo, options[:from], options[:to])
        @checker.when_useless_pattern do |record|
          suggest_fix_for record
        end

        @checker.when_new_file do |file|
          suggest_add_to_codeowners file
        end

        @checker.when_deleted_file do |file|
          suggest_remove_from_codeowners file
        end

        @checker.check!
        @checker.commit_changes! if options[:interactive] && yes?('Commit changes?')
      end

      desc 'changes SUBCOMMAND', 'List owners of changed files'
      subcommand 'changes', Code::Ownership::ChangesByOwner

      desc 'config', 'Checks config is consistent or configure it'
      option :team
      def config
        return unless validate_team_file && validate_team_options

        save_team if options[:team]
        team_name = IO.read(@default_team_file)
        puts "configured: #{team_name}"
      end

      private

      def save_team
        team_name = '@toptal/' + options[:team]
        File.open(@default_team_file, 'w+') { |file| file.puts team_name }
      end

      def validate_team_options
        return true unless options[:team]

        if options[:team] == 'team'
          puts 'Please provide a team name.',
               "Use #{$PROGRAM_NAME} --team <team-name>"
          return false
        end
        true
      end

      def validate_team_file
        return true if File.exist?(@default_team_file) || options[:team]

        puts 'Team name should be specified or a default team defined',
             "Try `#{$PROGRAM_NAME} --team <team-name>` to configure the team."
        false
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

        if owner && !owner.empty?
          @checker.codeowners_file.append pattern: file, owners: owner
          write_codeowners_file
        end
      end

      def suggest_remove_from_codeowners(file)
        record = @checker.codeowners_file.find_record_for_pattern pattern: file
        if record
          return unless yes?("File deleted: #{file}. Remove corresponding pattern from CODEOWNERS?")

          @checker.codeowners_file.delete line: record.line
          write_codeowners_file
        end
      end

      def suggest_fix_for(record)
        pattern = record.pattern
        search = FuzzyMatch.new(files_from(pattern))
        suggestion = search.find(pattern)
        apply_suggestion(record, suggestion) if suggestion
      end

      def apply_suggestion(record, suggestion)
        result = ask("Pattern #{record.pattern} doesn't match. Replace with: #{suggestion} (y), ignore (i) or delete pattern (d)?", limited_to: %w[y i d])
        return if result == 'i'

        if result == 'y'
          @checker.codeowners_file.update line: record.line, pattern: suggestion
        elsif result == 'd'
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
