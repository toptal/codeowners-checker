# frozen_string_literal: true

require 'set'

require 'code/ownership/checker/group/line'
require 'code/ownership/checker/parentable'
require 'code/ownership/checker/line_grouper'

module Code
  module Ownership
    class Checker
      class Group
        include Parentable

        def initialize
          @list = []
        end

        def parse(lines)
          LineGrouper.new(self, lines).call
        end

        def to_content
          @list.flat_map(&:to_content)
        end

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

        def add(content)
          content.parents << self
          @list << content
        end

        def insert(pattern)
          index = new_line_index(pattern)

          pattern.parents << self
          @list.insert(index, pattern)
        end

        def remove(content)
          @list.delete(content)
          remove! unless @list.any?(Pattern)
        end

        def remove!
          @list.each(&:remove!)
          super # TODO: it could be in parentable
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

        def new_line_index(pattern)
          patterns = @list.select { |item| item.is_a?(Pattern) }
          new_patterns_sorted = patterns.dup.push(pattern).sort
          new_pattern_index = new_patterns_sorted.index(pattern)

          if new_pattern_index > 0
            previous_line = new_patterns_sorted[new_pattern_index - 1]
            @list.index(previous_line) + 1
          else
            @list.index { |item| !item.is_a?(Comment) } || 0
          end
        end
      end
    end
  end
end
