# frozen_string_literal: true

require_relative '../interactive_ops'

module Codeowners
  module Cli
    module Wizards
      # Suggests to add new files to the codeowners list.
      # Only returns decision without applying any modifications.
      class NewFileWizard
        include InteractiveOps

        def initialize(default_owner)
          @default_owner = default_owner
        end

        def suggest_adding(file, main_group)
          case prompt(file)
          when 'y' then [:add, create_pattern(file, main_group)]
          when 'i' then :ignore
          when 'q' then :quit
          end
        end

        def select_operation(pattern, main_group)
          subgroups = main_group.subgroups_owned_by(pattern.owner)
          if subgroups.any? && (subgroup = prompt_subgroup(subgroups))
            [:insert_into_subgroup, subgroup]
          elsif yes?('Add to the end of the CODEOWNERS file?')
            :add_to_main_group
          else
            :ignore
          end
        end

        private

        def prompt(file)
          ask(<<~QUESTION, limited_to: %w[y i q])
            File added: #{file.inspect}. Add owner to the CODEOWNERS file?
            (y) yes
            (i) ignore
            (q) quit and save
          QUESTION
        end

        def create_pattern(file, main_group)
          sorted_owners = main_group.owners.sort
          owner = prompt_owner(sorted_owners)
          Codeowners::Checker::Group::Pattern.new("#{file} #{owner}")
        end

        def prompt_owner(sorted_owners)
          list_existing_owners(sorted_owners)
          loop do
            owner = do_prompt_owner(sorted_owners)

            unless Codeowners::Checker::Owner.valid?(owner)
              puts "#{owner.inspect} is not a valid owner name. Try again."
              next
            end

            return owner
          end
        end

        def list_existing_owners(sorted_owners)
          puts 'Owners:'
          sorted_owners.each_with_index { |owner, i| puts "#{i + 1} - #{owner}" }
          puts "Choose owner, add new one or leave empty to use #{@default_owner.inspect}."
        end

        def do_prompt_owner(sorted_owners)
          input = ask('New owner: ')

          if input.to_i.between?(1, sorted_owners.length)
            sorted_owners[input.to_i - 1]
          elsif input.empty?
            @default_owner
          else
            input
          end
        end

        def prompt_subgroup(subgroups)
          puts 'Possible groups to which the pattern belongs: '
          subgroups.each_with_index { |group, i| puts "#{i + 1} - #{group.title}" }
          choice = ask('Choose group: ').to_i
          subgroups[choice - 1] if choice.between?(1, subgroups.length)
        end
      end
    end
  end
end
