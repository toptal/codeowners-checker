# frozen_string_literal: true

require_relative 'line_grouper'
require_relative 'group/line'
require_relative 'array'

module Codeowners
  class Checker
    # Manage the groups content and handle operations on the groups.
    class Group
      include Enumerable

      attr_accessor :parent

      def self.parse(lines)
        new.parse(lines)
      end

      def initialize
        @list = []
      end

      def each(&block)
        @list.each do |object|
          if object.is_a?(Group)
            object.each(&block)
          else
            yield(object)
          end
        end
      end

      def parse(lines)
        LineGrouper.call(self, lines)
      end

      def to_content
        @list.flat_map(&:to_content)
      end

      def to_file
        @list.flat_map(&:to_file)
      end

      # Returns an array of strings representing the structure of the group.
      # It indent internal subgroups for readability and debugging purposes.
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
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
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def owner
        owners.first
      end

      # Owners are ordered by the amount of occurrences
      def owners
        all_owners.group_by(&:itself).sort_by do |_owner, occurrences|
          -occurrences.count
        end.map(&:first)
      end

      def subgroups_owned_by(owner)
        @list.flat_map do |item|
          next unless item.is_a?(Group)

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
        group = self.class.new
        group.parent = self
        @list << group
        group
      end

      def add(line)
        line.parent = self
        @list << line
      end

      def insert(line)
        line.parent = self
        index = insert_at_index(line)
        @list.insert(index, line)
      end

      def remove(line)
        @list.safe_delete(line)
        remove! unless any? { |object| object.is_a? Pattern }
      end

      def remove!
        @list.clear
        parent&.remove(self)
        self.parent = nil
      end

      def ==(other)
        other.is_a?(Group) && other.list == list
      end

      protected

      attr_accessor :list

      private

      def all_owners
        flat_map do |item|
          item.owners if item.pattern?
        end.compact
      end

      # rubocop:disable Metrics/AbcSize
      def insert_at_index(line)
        new_patterns_sorted = @list.grep(Pattern).dup.push(line).sort
        previous_line_index = new_patterns_sorted.index { |l| l.equal? line } - 1
        previous_line = new_patterns_sorted[previous_line_index]
        padding = previous_line.pattern.size + previous_line.whitespace - line.pattern.size
        line.whitespace = [1, padding].max

        if previous_line_index >= 0
          @list.index { |l| l.equal? previous_line } + 1
        else
          find_last_line_of_initial_comments
        end
      end
      # rubocop:enable Metrics/AbcSize

      def find_last_line_of_initial_comments
        @list.each_with_index do |item, index|
          return index unless item.is_a?(Comment)
        end
        0
      end
    end
  end
end
