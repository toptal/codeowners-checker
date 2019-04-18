# frozen_string_literal: true

require_relative '../checker'
require_relative 'base'
require_relative 'config'
require_relative 'filter'
require_relative 'suggest_file_from_pattern'
require_relative '../checker/owner'

module Codeowners
  module Cli
    # Command Line Interface used by bin/codeowners-checker.
    class Main < Base
      LABEL = { missing_ref: 'Missing references', useless_pattern: 'No files matching with the pattern' }.freeze
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true, type: :boolean, aliases: '-i'
      option :autocommit, default: false, type: :boolean, aliases: '-c'
      desc 'check REPO', 'Checks .github/CODEOWNERS consistency'
      # for pre-commit: --from HEAD --to index
      def check(repo = '.')
        @codeowners_changed = false
        @repo = repo
        setup_checker
        if options[:interactive]
          @checker.fix!
          if @codeowners_changed
            write_codeowners
            @checker.commit_changes! if options[:autocommit] || yes?('Commit changes?')
          end
        else
          if @checker.consistent?
            puts '✅ File is consistent'
            exit 0
          else
            puts "File #{@checker.codeowners_filename} is inconsistent:"
            report_errors!
            exit -1
          end
        end
      end

      desc 'filter <by-owner>', 'List owners of changed files'
      subcommand 'filter', Codeowners::Cli::Filter

      desc 'config', 'Checks config is consistent or configure it'
      subcommand 'config', Codeowners::Cli::Config

      private

      def setup_checker
        to = options[:to] != 'index' ? options[:to] : nil
        @checker = Codeowners::Checker.new(@repo, options[:from], to)
        @checker.when_useless_pattern = method(:suggest_fix_for)
        @checker.when_new_file = method(:suggest_add_to_codeowners)
        @checker.transformers << method(:unrecognized_line) if options[:interactive]
      end

      def write_codeowners
        @checker.codeowners.persist!
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

        @codeowners_changed = true
      end

      def create_new_pattern(file)
        sorted_owners = @checker.main_group.owners.sort
        list_owners(sorted_owners)
        loop do
          owner = new_owner(sorted_owners)

          unless Codeowners::Checker::Owner.valid?(owner)
            puts "#{owner.inspect} is not a valid owner name. Try again."
            next
          end

          return Codeowners::Checker::Group::Pattern.new("#{file} #{owner}")
        end
      end

      def list_owners(sorted_owners)
        puts 'Owners:'
        sorted_owners.each_with_index { |owner, i| puts "#{i + 1} - #{owner}" }
        puts "Choose owner, add new one or leave empty to use #{@config.default_owner.inspect}."
      end

      def new_owner(sorted_owners)
        owner = ask('New owner: ')

        if owner.to_i.between?(1, sorted_owners.length)
          sorted_owners[owner.to_i - 1]
        elsif owner.empty?
          @config.default_owner
        else
          owner
        end
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

        @codeowners_changed = true
      end

      def apply_suggestion(line, suggestion)
        case make_suggestion(suggestion)
        when 'i' then nil
        when 'y'
          line.pattern = suggestion
        when 'e'
          pattern_change(line)
        when 'd'
          line.remove!
        when 'q'
          throw :user_quit
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
        begin
          new_line_string = ask('New line: ')
          line = Codeowners::Checker::Group::Line.build(new_line_string)
        end while line.is_a?(Codeowners::Checker::Group::UnrecognizedLine)
        @codeowners_changed = true
        line
      end

      def ask(message, *opts)
        return unless options[:interactive]

        super
      end

      def yes?(message, *opts)
        return unless options[:interactive]

        super
      end

      LABELS = {
        missing_ref: 'No owner defined',
        useless_pattern: 'Useless patterns'
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
