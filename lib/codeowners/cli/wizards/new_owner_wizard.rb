# frozen_string_literal: true

require_relative '../interactive_ops'

module Codeowners
  module Cli
    module Wizards
      # Suggests to add new owners to the owners list.
      # Only returns decision without applying any modifications.
      class NewOwnerWizard
        include InteractiveOps

        def initialize(owners_list)
          @owners_list = owners_list
        end

        def suggest_fixing(line, new_owner)
          case prompt(line, new_owner)
          when 'y' then :add
          when 'r' then [:rename, keep_asking_until_valid_owner]
          when 'i' then :ignore
          when 'q' then :quit
          end
        end

        private

        def prompt(line, new_owner)
          ask(<<~QUESTION, limited_to: %w[y r i q])
            Unknown owner: #{new_owner} for pattern: #{line.pattern}. Add owner to the OWNERS file?
            (y) yes
            (r) rename owner
            (i) ignore owner in this session
            (q) quit and save
          QUESTION
        end

        def keep_asking_until_valid_owner
          owner = nil
          loop do
            owner = ask('New owner: ')
            break if @owners_list.valid_owner?(owner)
          end
          owner
        end
      end
    end
  end
end
