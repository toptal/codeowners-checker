# frozen_string_literal: true

require_relative '../interactive_ops'

module Codeowners
  module Cli
    module Wizards
      # Attempt to find a name similar to one provided in the owners list.
      # Suggest to add new owner to the owners list.
      # Only return decision without applying any modifications.
      class NewOwnerWizard
        include InteractiveOps

        DEFAULT_OPTIONS = {
          'a' => '(a) add a new owner',
          'r' => '(r) rename owner',
          'i' => '(i) ignore owner in this session',
          'q' => '(q) quit and save'
        }.freeze

        def initialize(owners_list)
          @owners_list = owners_list
        end

        def suggest_fixing(line, new_owner)
          suggested_owner = suggest_name_from_owners_list(new_owner)
          case prompt(line, new_owner, suggested_owner)
          when 'y' then [:rename, suggested_owner]
          when 'a' then :add
          when 'r' then [:rename, keep_asking_until_valid_owner]
          when 'i' then :ignore
          when 'q' then :quit
          end
        end

        private

        def suggest_name_from_owners_list(new_owner)
          require 'fuzzy_match'
          search = FuzzyMatch.new(@owners_list.owners)
          (suggested_owner, dice, _lev) = search.find_with_score(new_owner)
          return suggested_owner if dice && dice > 0.6
        end

        def prompt(line, new_owner, suggested_owner)
          prompt_options = build_prompt_options(suggested_owner)
          ask(<<~QUESTION, limited_to: prompt_options.keys)
            #{question_body(line, new_owner, suggested_owner)}
            #{question_options(prompt_options)}
          QUESTION
        end

        def question_body(line, new_owner, suggested_owner)
          prompt = "Unknown owner: #{new_owner} for pattern: #{line.pattern}."
          if suggested_owner
            prompt + " Did you mean #{suggested_owner}?"
          else
            prompt + ' Choose an option:'
          end
        end

        def question_options(accepted_options)
          accepted_options.values.join("\n")
        end

        def build_prompt_options(suggested_owner)
          return DEFAULT_OPTIONS unless suggested_owner

          { 'y' => "(y) correct to #{suggested_owner}" }.merge(DEFAULT_OPTIONS)
        end

        def keep_asking_until_valid_owner
          loop do
            owner = ask('New owner: ')
            owner = '@' + owner unless owner[0] == '@'
            return owner if @owners_list.valid_owner?(owner)
          end
        end
      end
    end
  end
end
