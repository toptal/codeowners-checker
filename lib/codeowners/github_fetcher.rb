# frozen_string_literal: true

require 'rest-client'
require 'json'

module Codeowners
  # Fetch teams and members from GitHub and return them in list
  class GithubFetcher
    class << self
      GITHUB_URL = 'https://api.github.com'

      # Fetch teams and members from GitHub.
      # authorization_token is GitHub PAT with read:org scope
      # @return <Array> with GitHub teams and individuals belonging to a given GitHub organization
      def get_owners(github_org, authorization_token)
        headers = get_headers(authorization_token)
        base_url = GITHUB_URL + '/orgs/' + github_org
        owners = []
        list_entities(base_url + '/teams', headers) { |team| owners << "@#{github_org}/#{team['slug']}" }
        list_entities(base_url + '/members', headers) { |member| owners << "@#{member['login']}" }
        owners
      end

      private

      # Helper method to get properly formatted HTTP headers
      def get_headers(authorization_token)
        {
          Accept: 'application/vnd.github.v3+json',
          Authorization: "token #{authorization_token}"
        }
      end

      # Helper method that loops through all pages if GitHub returns a paged response
      def list_entities(first_page, headers)
        next_page = first_page
        loop do
          response = RestClient.get(next_page, headers)
          response_json = JSON.parse(response.body)
          response_json.each { |entity| yield entity }
          next_page = get_next_page(response)
          break unless next_page
        end
      end

      # Helper method to parse and get URL of the next page from 'link' response header
      def get_next_page(response)
        return nil unless response.headers[:link]

        matches = response.headers[:link].match('<([^>]+)>; rel="next"')
        return matches[1] if matches
      end
    end
  end
end
