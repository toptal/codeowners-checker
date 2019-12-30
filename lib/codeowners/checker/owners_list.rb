# frozen_string_literal: true

require_relative 'file_as_array'

module Codeowners
  class Checker
    # Manage OWNERS file reading, re-writing and fetching
    class OwnersList
      attr_accessor :validate_owners, :filename
      attr_writer :owners

      def initialize(repo)
        @validate_owners = true
        # doing gsub here ensures the files are always in the same directory
        @filename = CodeOwners.filename(repo).gsub('CODEOWNERS', 'OWNERS')
      end

      def self.persist!(repo, owners)
        owner_list = new(repo)
        owner_list.owners = owners
        owner_list.persist!
      end

      def persist!
        owners_file = FileAsArray.new(@filename)
        owners_file.content = @owners
        owners_file.persist!
      end

      def valid_owner?(owner)
        !@validate_owners || owners.include?(owner)
      end

      def owners
        return [] unless @validate_owners

        @owners ||=
          if github_credentials_exist?
            Codeowners::GithubFetcher.get_owners(ENV['GITHUB_ORGANIZATION'], ENV['GITHUB_TOKEN'])
          else
            FileAsArray.new(@filename).content
          end
      end

      def github_credentials_exist?
        token = ENV['GITHUB_TOKEN']
        organization = ENV['GITHUB_ORGANIZATION']
        token && organization
      end

      def invalid_owners(codeowners)
        return [] unless @validate_owners

        codeowners.each_with_object([]) do |line, acc|
          next unless line.pattern?

          missing = line.owners - owners
          acc.push([line, missing]) if missing.any?
        end
      end

      def <<(owner)
        return if @owners.include?(owner)

        @owners << owner
      end
    end
  end
end
