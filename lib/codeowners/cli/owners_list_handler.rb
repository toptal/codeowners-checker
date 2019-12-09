# frozen_string_literal: true

require_relative '../checker/owners_list'

module Codeowners
  module Cli
    # Command Line Interface dealing with OWNERS generation and validation
    class OwnersListHandler < Base
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
        def owners_from_github
          organization = ENV['GITHUB_ORGANIZATION']
          organization ||= ask('GitHub organization (e.g. github): ')
          token = ENV['GITHUB_TOKEN']
          token ||= ask('Enter GitHub token: ', echo: false)
          puts 'Fetching owners list from GitHub ...'
          Codeowners::GithubFetcher.get_owners(organization, token)
        end
      end
    end
  end
end
