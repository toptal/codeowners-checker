# frozen_string_literal: true

require_relative 'group'

module Codeowners
  class Checker
    # Manage CODEOWNERS file reading and re-writing.
    class CodeOwners
      attr_reader :list, :main_group, :file_manager

      def initialize(file_manager)
        @file_manager = file_manager
        parse_file
        @main_group = Group.parse(@list)
      end

      def persist!
        file_manager.content = main_group.to_content
      end

      def remove(content)
        @list.delete(content)
      end

      private

      def parse_file
        @list = @file_manager.content.map(&Codeowners::Checker::Group::Line.method(:build))
        @list.each { |line| line.parents << self }
        # TODO: ask the user to fix unrecognized lines?
      end
    end
  end
end
