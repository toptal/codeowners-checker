# frozen_string_literal: true

require_relative 'file_as_array'

module Codeowners
  class Checker
    # Manage OWNERS file reading, re-writing and fetching
    class OwnersList
      attr_accessor :validate_owners, :when_new_owner, :ownerslist_filename
      attr_writer :owners

      def initialize(ownerslist_filename)
        @validate_owners = true
        @ownerslist_filename = ownerslist_filename
      end

      def persist!
        owners_file = FileAsArray.new(@ownerslist_filename)
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
            FileAsArray.new(@ownerslist_filename).content
          end
      end

      def github_credentials_exist?
        token = ENV['GITHUB_TOKEN']
        organization = ENV['GITHUB_ORGANIZATION']
        token && organization
      end

      def invalid_owner(codeowners)
        return [] unless @validate_owners

        codeowners.select do |line|
          next unless line.pattern?

          missing = line.owners - owners
          missing.each { |owner| @when_new_owner&.call(line, owner) }
          missing.any?
        end
      end

      def <<(owner)
        @owners << owner
      end
    end
  end
end
