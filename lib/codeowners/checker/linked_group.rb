# frozen_string_literal: true

require_relative 'line_grouper'
require_relative 'parentable'
require_relative 'group/line'
require_relative 'array'

module Codeowners
  class Checker
    # Manage the groups content and handle operations on the groups.
    class LinkedGroup < Group
      attr_accessor :parent_file

      def self.parse(lines, parent_file)
        new(parent_file).parse(lines)
      end

      def initialize(parent_file)
        @parent_file = parent_file
        super()
      end

      def remove(line)
        @list.safe_delete(line)
        remove! unless @list.any?(Pattern)
      end

      def remove!
        super
        parent_file&.remove(self)
        parent_file = nil
      end

      protected

      attr_accessor :list

      private

      def new_group
        self.class.new(parent_file)
      end

      def insert_after(previous_line, line)
        super
        parent_file&.insert_after(previous_line, line)
      end
    end
  end
end
