# frozen_string_literal: true

require "delegate"

require_relative 'line_grouper'
require_relative 'parentable'
require_relative 'group/line'
require_relative 'array'

module Codeowners
  class Checker
    # Manage the groups content and handle operations on the groups.
    class LinkedGroup < SimpleDelegator

      def self.parse(lines, parent_file)
        new(Group.parse(lines), parent_file).parse(lines)
      end

      def initialize(group, linked_to)
        super(group)
        @group = group
        @linked_to = linked_to
      end

      def remove!
        @group.remove!
        @linked_to&.remove(self)
        @linked_to = nil
      end

      protected

      attr_accessor :list

      private

      def add_subgroup group = LinkedGroup.new(Group.new, @linked_to)
        @group.add_subgroup group
      end

      def insert_after(previous_line, line)
        super
        @parent_file&.insert_after(previous_line, line)
      end
    end
  end
end
