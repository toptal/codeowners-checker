# frozen_string_literal: true

require_relative 'wizards/new_file_wizard'
require_relative 'wizards/new_owner_wizard'
require_relative 'wizards/unrecognized_line_wizard'
require_relative 'wizards/useless_pattern_wizard'

module Codeowners
  module Cli
    # Resolve issues in interactive mode
    # handle_* methods will throw :user_quit
    # if the user chose to save and quit
    class InteractiveResolver
      def initialize(checker, validate_owners, default_owner)
        @checker = checker
        @ignored_owners = []
        @validate_owners = validate_owners
        @default_owner = default_owner
        create_wizards
      end

      def handle(error_type, inconsistencies, meta)
        case error_type
        when :useless_pattern then handle_useless_pattern(inconsistencies)
        when :missing_ref then handle_new_file(inconsistencies)
        when :invalid_owner then handle_new_owner(inconsistencies, meta)
        when :unrecognized_line then process_parsed_line(inconsistencies)
        else raise ArgumentError, "unknown error_type: #{error_type}"
        end
      end

      def handle_new_file(file) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        choice, pattern = @new_file_wizard.suggest_adding(file, @checker.main_group)
        throw :user_quit if choice == :quit
        return unless choice == :add

        validate_owner(pattern, pattern.owner) if @validate_owners
        op, subgroup = @new_file_wizard.select_operation(pattern, @checker.main_group)
        case op
        when :insert_into_subgroup
          subgroup.insert(pattern)
          @made_changes = true
        when :add_to_main_group
          @checker.main_group.add(pattern)
          @made_changes = true
        end
      end

      def handle_new_owner(line, owner)
        return if @ignored_owners.include?(owner)

        choice = @new_owner_wizard.suggest_adding(line, owner)
        case choice
        when :add
          @checker.owners_list << owner
          @made_changes = true
        when :ignore
          @ignored_owners << owner
        when :quit then throw :user_quit
        end
      end

      def handle_useless_pattern(line)
        choice, new_pattern = @useless_pattern_wizard.suggest_fixing(line)
        case choice
        when :replace
          line.pattern = new_pattern
          @made_changes = true
        when :delete
          line.remove!
          @made_changes = true
        when :quit then throw :user_quit
        end
      end

      def process_parsed_line(line) # rubocop:disable Metrics/MethodLength
        return line unless line.is_a?(Codeowners::Checker::Group::UnrecognizedLine)

        choice, new_line = @unrecognized_line_wizard.suggest_fixing(line)
        case choice
        when :replace
          @made_changes = true
          new_line
        when :delete
          @made_changes = true
          nil
        when :ignore then line
        end
      end

      def print_epilogue
        return unless @ignored_owners.any?

        puts 'Ignored owners:'
        @ignored_owners.each do |owner|
          puts " * #{owner}"
        end
      end

      def made_changes?
        @made_changes
      end

      private

      def create_wizards
        @new_owner_wizard = Wizards::NewOwnerWizard.new
        @new_file_wizard = Wizards::NewFileWizard.new(@default_owner)
        @useless_pattern_wizard = Wizards::UselessPatternWizard.new
        @unrecognized_line_wizard = Wizards::UnrecognizedLineWizard.new
      end

      def validate_owner(pattern, owner)
        return if @checker.owners_list.valid_owner?(pattern.owner)

        handle_new_owner(pattern, owner)
      end
    end
  end
end
