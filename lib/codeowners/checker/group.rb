# frozen_string_literal: true

require_relative 'line_grouper'
require_relative 'parentable'
require_relative 'group/line'
require_relative 'array'

module Codeowners
  class Checker
    # Manage the groups content and handle operations on the groups.
    class Group
      include Parentable

      def self.parse(lines, parent_file = nil)
        new(parent_file).parse(lines)
      end

      def initialize(parent_file = nil)
        @parent_file = parent_file
        @list = []
      end

      def parse(lines)
        LineGrouper.call(self, lines)
      end

      def to_content
        @list.flat_map(&:to_content)
      end

      # Returns an array of strings representing the structure of the group.
      # It indent internal subgroups for readability and debugging purposes.
      def to_tree(indentation = '')
        @list.each_with_index.flat_map do |item, index|
          if indentation.empty?
            item.to_tree(indentation + ' ')
          elsif index.zero?
            item.to_tree(indentation + '+ ')
          elsif index == @list.length - 1
            item.to_tree(indentation + '\\ ')
          else
            item.to_tree(indentation + '| ')
          end
        end
      end

      def owner
        owners.first
      end

      # Owners are ordered by the amount of occurences
      def owners
        all_owners.group_by(&:itself).sort_by do |_owner, occurences|
          -occurences.count
        end.map(&:first)
      end

      def subgroups_owned_by(owner)
        @list.flat_map do |item|
          return [] unless item.is_a?(Group)

          a = []
          a << item if item.owner == owner
          a += item.subgroups_owned_by(owner)
          a
        end.compact
      end

      def title
        @list.first.to_s
      end

      def create_subgroup
        group = Group.new
        group.parent_file = parent_file
        @list << group
        group
      end

      def add(line)
        previous_line = @list.last
        insert_after(previous_line, line)
        parent_file&.insert_after(previous_line, line)
      end

      def insert(line)
        previous_line = find_previous_line(line)
        insert_after(previous_line, line)
        parent_file&.insert_after(previous_line, line)
      end

      def remove(line)
        @list.safe_delete(line)
        remove! unless @list.any?(Pattern)
      end

      def remove!
        @list.each(&:remove!)
        super
      end

      def ==(other)
        other.is_a?(Group) && other.list == list
      end

      protected

      attr_accessor :list

      private

      def all_owners
        @list.flat_map do |item|
          item.owners if item.respond_to?(:owners)
        end.compact
      end

      def find_previous_line(line)
        patterns = @list.grep(Pattern)
        new_patterns_sorted = patterns.dup.push(line).sort
        new_pattern_index = new_patterns_sorted.index(line)

        if new_pattern_index > 0
          new_patterns_sorted[new_pattern_index - 1]
        else
          find_last_line_of_initial_comments
        end
      end

      def find_last_line_of_initial_comments
        @list.inject(nil) do |previous, item|
          if item.is_a?(Comment)
            item
          else
            return previous
          end
        end
      end

      def insert_after(previous_line, line)
        previous_index = @list.index(previous_line)
        index = previous_index ? previous_index + 1 : 0

        line.parent_group = self
        @list.insert(index, line)
      end
    end
  end
end
