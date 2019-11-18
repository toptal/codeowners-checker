# frozen_string_literal: true

require_relative '../checker'
require_relative 'base'
require_relative 'config'
require_relative 'filter'
require_relative 'owners_list_handler'
require_relative '../github_fetcher'
require_relative 'suggest_file_from_pattern'
require_relative '../checker/owner'

module Codeowners
  module Cli
    # Command Line Interface used by bin/codeowners-checker.
    class Main < Base # rubocop:disable Metrics/ClassLength
      include InteractiveHelpers

      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true, type: :boolean, aliases: '-i'
      option :validateowners, default: true, type: :boolean, aliases: '-v'
      option :autocommit, default: false, type: :boolean, aliases: '-c'
      desc 'check REPO', 'Checks .github/CODEOWNERS consistency'
      # for pre-commit: --from HEAD --to index
      def check(repo = '.') # rubocop:disable Metrics/MethodLength
        @content_changed = false
        @repo = repo
        setup_checker
        @owners_list_handler = OwnersListHandler.new
        @owners_list_handler.checker = @checker
        @owners_list_handler.options = options
        if options[:interactive]
          interactive_mode
        else
          report_inconsistencies
        end
      end

      desc 'filter <by-owner>', 'List owners of changed files'
      subcommand 'filter', Codeowners::Cli::Filter

      desc 'config', 'Checks config is consistent or configure it'
      subcommand 'config', Codeowners::Cli::Config

      desc 'fetch [REPO]', 'Fetches .github/OWNERS based on github organization'
      subcommand 'fetch', Codeowners::Cli::OwnersListHandler

      private

      def interactive_mode
        @checker.fix!
        return unless content_changed

        write_changes
        @checker.commit_changes! if options[:autocommit] || yes?('Commit changes?')
      end

      def report_inconsistencies
        if @checker.consistent?
          puts '✅ File is consistent'
          exit 0
        else
          puts "File #{@checker.codeowners.filename} is inconsistent:"
          report_errors!
          exit(-1)
        end
      end

      def setup_checker # rubocop:disable Metrics/AbcSize
        to = options[:to] != 'index' ? options[:to] : nil
        @checker = Codeowners::Checker.new(@repo, options[:from], to)
        @checker.when_useless_pattern = method(:suggest_fix_for)
        @checker.when_new_file = method(:suggest_add_to_codeowners)
        @checker.transformers << method(:unrecognized_line) if options[:interactive]
        @checker.owners_list.when_new_owner = method(:suggest_add_to_owners_list)
        @checker.owners_list.validate_owners = options[:validateowners]
      end

      def suggest_add_to_owners_list(file, owner)
        @owners_list_handler.suggest_add_to_owners_list(file, owner)
      end

      def write_changes
        @checker.codeowners.persist!
        @checker.owners_list.persist!
      end

      def content_changed
        @content_changed || @owners_list_handler.content_changed
      end

      def suggest_add_to_codeowners(file)
        case add_to_codeowners_dialog(file)
        when 'y' then add_to_codeowners(file)
        when 'i' then nil
        when 'q' then throw :user_quit
        end
      end

      def add_to_codeowners_dialog(file)
        ask(<<~QUESTION, limited_to: %w[y i q])
          File added: #{file.inspect}. Add owner to the CODEOWNERS file?
          (y) yes
          (i) ignore
          (q) quit and save
        QUESTION
      end

      def add_to_codeowners(file)
        new_line = create_new_pattern(file)

        subgroups = @checker.main_group.subgroups_owned_by(new_line.owner)
        add_pattern(new_line, subgroups)

        @content_changed = true
      end

      def list_owners(sorted_owners)
        puts 'Owners:'
        sorted_owners.each_with_index { |owner, i| puts "#{i + 1} - #{owner}" }
        puts "Choose owner, add new one or leave empty to use #{@config.default_owner.inspect}."
      end

      def create_new_pattern(file)
        sorted_owners = @checker.main_group.owners.sort
        list_owners(sorted_owners)
        if @options[:validateowners]
          return @owners_list_handler.create_new_pattern_with_validated_owner(file, sorted_owners)
        end

        @owners_list_handler.create_new_pattern_with_owner(file, sorted_owners)
      end

      def add_pattern(pattern, subgroups)
        unless subgroups.empty?
          return if insert_pattern_into_subgroup(pattern, subgroups)
        end

        @checker.main_group.add(pattern) if yes?('Add to the end of the CODEOWNERS file?')
      end

      def insert_pattern_into_subgroup(pattern, subgroups)
        subgroup = suggest_subgroups_for_pattern(subgroups).to_i - 1
        return unless subgroup >= 0 && subgroup < subgroups.length

        subgroups[subgroup].insert(pattern)
        true
      end

      def suggest_subgroups_for_pattern(subgroups)
        puts 'Possible groups to which the pattern belongs: '
        subgroups.each_with_index { |group, i| puts "#{i + 1} - #{group.title}" }
        ask('Choose group: ')
      end

      def suggest_fix_for(line)
        return unless options[:interactive]

        puts "Pattern #{line.pattern.inspect} doesn't match."
        suggestion = Codeowners::Cli::SuggestFileFromPattern.new(line.pattern).pick_suggestion

        # TODO: Handle duplicate patterns.
        if suggestion
          apply_suggestion(line, suggestion)
        else
          pattern_fix(line)
        end

        @content_changed = true
      end

      def apply_suggestion(line, suggestion)
        case make_suggestion(suggestion)
        when 'i' then nil
        when 'y' then line.pattern = suggestion
        when 'e' then pattern_change(line)
        when 'd' then line.remove!
        when 'q' then throw :user_quit
        end
      end

      def make_suggestion(suggestion)
        ask(<<~QUESTION, limited_to: %w[y i e d q])
          Replace with: #{suggestion.inspect}?
          (y) yes
          (i) ignore
          (e) edit the pattern
          (d) delete the pattern
          (q) quit and save
        QUESTION
      end

      def pattern_fix(line)
        case pattern_suggest_fixing
        when 'e' then pattern_change(line)
        when 'i' then nil
        when 'd' then line.remove!
        when 'q' then throw :user_quit
        end
      end

      def pattern_suggest_fixing
        ask(<<~QUESTION, limited_to: %w[i e d q])
          (e) edit the pattern
          (d) delete the pattern
          (i) ignore
          (q) quit and save
        QUESTION
      end

      def pattern_change(line)
        new_pattern = ask("Replace pattern #{line.pattern.inspect} with: ")
        return if new_pattern.empty?

        line.pattern = new_pattern
      end

      def unrecognized_line(line)
        return line unless line.is_a?(Codeowners::Checker::Group::UnrecognizedLine)

        case unrecognized_line_suggest_fixing(line)
        when 'i' then line
        when 'y' then unrecognized_line_new_line
        when 'd' then nil
        end
      end

      def unrecognized_line_suggest_fixing(line)
        ask(<<~QUESTION, limited_to: %w[y i d])
          #{line.to_s.inspect} is in unrecognized format. Would you like to edit?
          (y) yes
          (i) ignore
          (d) delete the line
        QUESTION
      end

      def unrecognized_line_new_line
        line = nil
        loop do
          new_line_string = ask('New line: ')
          line = Codeowners::Checker::Group::Line.build(new_line_string)
          break unless line.is_a?(Codeowners::Checker::Group::UnrecognizedLine)
        end
        @content_changed = true
        line
      end
      LABELS = {
        missing_ref: 'No owner defined',
        useless_pattern: 'Useless patterns',
        invalid_owner: 'Invalid owner',
        unrecognized_line: 'Unrecognized line'
      }.freeze

      def report_errors!
        @checker.fix!.each do |error_type, inconsistencies|
          next if inconsistencies.empty?

          puts LABELS[error_type], '-' * 30, inconsistencies, '-' * 30
        end
      end
    end
  end
end
