# frozen_string_literal: true

require 'fuzzy_match'
require_relative '../checker'
require_relative 'base'
require_relative 'config'
require_relative 'filter'

module Code
  module Ownership
    module Cli
      # Command Line Interface used by bin/code-owners-checker.
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
        subcommand 'filter', Code::Ownership::Cli::Filter

        desc 'config', 'Checks config is consistent or configure it'
        subcommand 'config', Code::Ownership::Cli::Config

        # desc 'check', 'Checks .github/CODEOWNERS consistency'
        # subcommand 'check', Code::Ownership::Cli::Check

        private

        def setup_checker
          to = options[:to] != 'index' ? options[:to] : nil
          @checker = Code::Ownership::Checker.new(@repo, options[:from], to)
          @checker.when_useless_pattern = method(:suggest_fix_for)
          @checker.when_new_file = method(:suggest_add_to_codeowners)
        end

        def write_codeowners
          @checker.codeowners.persist!
        end

        def suggest_add_to_codeowners(file)
          return unless yes?("File added: #{file}. Add owner to CODEOWNERS?")

          owner = ask('File owner(s): ')

          return if owner.empty?

          line = "#{file} #{owner}"
          pattern = Code::Ownership::Checker::Group::Line.build(line)
          subgroups = @checker.codeowners.main_group.subgroups_owned_by(pattern.owner)
          add_pattern(pattern, subgroups)

          @codeowners_changed = true
        end

        def add_pattern(pattern, subgroups)
          unless subgroups.empty?
            return if insert_into_group(pattern, subgroups) == true
          end

          @checker.codeowners.main_group.add(pattern) if yes?('Add to the end of the codeowners file?')
        end

        def insert_into_group(pattern, subgroups)
          subgroup = suggest_groups(subgroups).to_i - 1
          return unless subgroup >= 0 && subgroup < subgroups.length

          subgroups[subgroup].insert(pattern)
          true
        end

        def suggest_groups(subgroups)
          puts 'Possible groups to which the pattern belongs: '
          subgroups.each_with_index { |group, i| puts "#{i + 1} - #{group.title}" }
          ask('Choose group: ')
        end

        def suggest_fix_for(line)
          # TODO: allow user to fix the pattern if no good suggestion
          search = FuzzyMatch.new(line.suggest_files_for_pattern)
          suggestion = search.find(line.pattern)
          apply_suggestion(line, suggestion) if suggestion
        end

        def make_suggestion(line, suggestion)
          ask(<<~QUESTION, limited_to: %w[y i d])
            Pattern #{line.pattern} doesn't match.
            Replace with: #{suggestion}?
            (y) yes
            (i) ignore
            (d) delete the pattern
          QUESTION
        end

        def apply_suggestion(line, suggestion)
          case make_suggestion(line, suggestion)
          when 'i' then return
          when 'y'
            line.pattern = suggestion
          when 'd'
            line.remove!
          end
          @codeowners_changed = true
        end
      end
    end
  end
end
