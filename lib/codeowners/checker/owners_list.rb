# frozen_string_literal: true

require_relative 'file_as_array'
require_relative '../config'

module Codeowners
  class Checker
    # Manage OWNERS file reading, re-writing and fetching
    class OwnersList
      attr_accessor :validate_owners, :filename
      attr_writer :owners

      def initialize(repo, _config = nil)
        @validate_owners = true
        # doing gsub here ensures the files are always in the same directory
        @filename = CodeOwners.filename(repo).gsub('CODEOWNERS', 'OWNERS')
        @config ||= Codeowners::Config.new
      end

      def self.persist!(repo, owners, config = nil)
        owner_list = new(repo, config)
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
            Codeowners::GithubFetcher.get_owners(@config.default_organization, ENV['GITHUB_TOKEN'])
          else
            FileAsArray.new(@filename).content
          end
      end

      def github_credentials_exist?
        token = ENV['GITHUB_TOKEN']
        organization = @config.default_organization
        token && !organization.empty?
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
