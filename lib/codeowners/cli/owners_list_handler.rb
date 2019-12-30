# frozen_string_literal: true

require_relative '../checker/owners_list'

module Codeowners
  module Cli
    # Command Line Interface dealing with OWNERS generation and validation
    class OwnersListHandler < Base
      default_task :fetch

      FETCH_OWNER_MESSAGE = 'Fetching owners list from GitHub ...'
      ASK_GITHUB_ORGANIZATION = 'GitHub organization (e.g. github): '
      ASK_GITHUB_TOKEN = 'Enter GitHub token: '

      desc 'fetch [REPO]', 'Fetches .github/OWNERS based on github organization'
      def fetch(repo = '.')
        @repo = repo
        owners = owners_from_github
        Checker::OwnersList.persist!(repo, owners)
      end

      no_commands do
        def owners_from_github
          organization = ENV['GITHUB_ORGANIZATION']
          organization ||= ask(ASK_GITHUB_ORGANIZATION)
          token = ENV['GITHUB_TOKEN']
          token ||= ask(ASK_GITHUB_TOKEN, echo: false)
          puts FETCH_OWNER_MESSAGE
          Codeowners::GithubFetcher.get_owners(organization, token)
        end
      end
    end
  end
end
