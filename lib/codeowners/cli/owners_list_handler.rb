# frozen_string_literal: true

require_relative '../checker'
require_relative '../checker/owners_list'
require_relative 'interactive_helpers'

module Codeowners
  module Cli
    # Command Line Interface dealing with OWNERS generation and validation
    class OwnersListHandler < Base
      include InteractiveHelpers

      attr_writer :checker
      attr_reader :content_changed, :ignored_owners
      default_task :fetch

      desc 'fetch [REPO]', 'Fetches .github/OWNERS based on github organization'
      def fetch(repo = '.')
        @repo = repo
        owners = owners_from_github
        owners_list = Checker::OwnersList.new(repo)
        owners_list.owners = owners
        owners_list.persist!
      end

      no_commands do
        def initialize
          super
          @ignored_owners = []
        end

        def owners_from_github
          organization = ENV['GITHUB_ORGANIZATION']
          organization ||= ask('GitHub organization (e.g. github): ')
          token = ENV['GITHUB_TOKEN']
          token ||= ask('Enter GitHub token: ', echo: false)
          puts 'Fetching owners list from GitHub ...'
          Codeowners::GithubFetcher.get_owners(organization, token)
        end

        def suggest_add_to_owners_list(line, owner)
          return nil if ignored_owners.include?(owner)

          case add_to_ownerslist_dialog(line, owner)
          when 'y' then add_to_ownerslist(owner)
          when 'i'
            ignored_owners << owner
            nil
          when 'q' then throw :user_quit
          end
        end

        def add_to_ownerslist_dialog(line, owner)
          ask(<<~QUESTION, limited_to: %w[y i q])
            Unknown owner: #{owner} for pattern: #{line.pattern}. Add owner to the OWNERS file?
            (y) yes
            (i) ignore owner in this session
            (q) quit and save
          QUESTION
        end

        def add_to_ownerslist(owner)
          @checker.owners_list << owner
          @content_changed = true
        end

        def create_new_pattern_with_owner(file, sorted_owners)
          loop do
            owner = new_owner(sorted_owners)

            unless Codeowners::Checker::Owner.valid?(owner)
              puts "#{owner.inspect} is not a valid owner name. Try again."
              next
            end

            return Codeowners::Checker::Group::Pattern.new("#{file} #{owner}")
          end
        end

        def create_new_pattern_with_validated_owner(file, sorted_owners)
          # first make sure we have the '@' sign in owner
          pattern = create_new_pattern_with_owner(file, sorted_owners)
          return pattern if @checker.owners_list.valid_owner?(pattern.owner)

          # The following call will either
          #   - (i)gnore: the bad owner and thus the user intention is explicit and we will create the Pattern
          #   - (y)es: user is added to OWNERS and thus the Pattern will be valid
          # The side-effect of ignore is that the same validation and the same question will be asked again
          # after the pattern validation finishes and the owners validation starts
          suggest_add_to_owners_list(pattern, pattern.owner)
          pattern
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
      end
    end
  end
end
