# frozen_string_literal: true

require 'fuzzy_match'

require_relative '../checker'
require_relative 'base'
require_relative 'config'
require_relative 'filter'

module Codeowners
  module Cli
    # Command Line Interface used by bin/codeowners-checker.
    class Main < Base
      LABEL = { missing_ref: 'Missing references', useless_pattern: 'No files matching with the pattern' }.freeze
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true, type: :boolean, aliases: '-i'
      desc 'check REPO', 'Checks .github/CODEOWNERS consistency'
      # for pre-commit: --from HEAD --to index
      def check(repo = '.')
        @codeowners_changed = false
        @repo = repo
        setup_checker
        @checker.check!
        write_codeowners if @codeowners_changed
        @checker.commit_changes! if options[:interactive] && yes?('Commit changes?')
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
        @checker.transformers << method(:unrecognized_line)
      end

      def write_codeowners
        @checker.codeowners.persist!
      end

      def suggest_add_to_codeowners(file)
        return unless yes?("File added: #{file.inspect}. Add owner to the CODEOWNERS file?")

        owner = ask('File owner(s): ')
        new_line = create_new_pattern(file, owner)

        unless new_line.pattern?
          puts "#{owner.inspect} is not a valid owner name."
          return
        end

        subgroups = @checker.main_group.subgroups_owned_by(new_line.owner)
        add_pattern(new_line, subgroups)

        @codeowners_changed = true
      end

      def create_new_pattern(file, owner)
        line = "#{file} #{owner}"
        Codeowners::Checker::Group::Line.build(line)
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
        search = FuzzyMatch.new(line.suggest_files_for_pattern)
        suggestion = search.find(line.pattern)

        puts "Pattern #{line.pattern.inspect} doesn't match."

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
        end
      end

      def make_suggestion(suggestion)
        ask(<<~QUESTION, limited_to: %w[y i e d])
          Replace with: #{suggestion.inspect}?
          (y) yes
          (i) ignore
          (e) edit the pattern
          (d) delete the pattern
        QUESTION
      end

      def pattern_fix(line)
        case pattern_suggest_fixing
        when 'e' then pattern_change(line)
        when 'i' then nil
        when 'd' then line.remove!
        end
      end

      def pattern_suggest_fixing
        ask(<<~QUESTION, limited_to: %w[i e d])
          (e) edit the pattern
          (d) delete the pattern
          (i) ignore
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
    end
  end
end
