# frozen_string_literal: true

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

        def to_tree(indentation = '  ', level = 0)
          @list.flat_map { |item| item.to_tree(indentation, level + 1) }
        end

        def add(content)
          content.parent = self
          @list << content
        end

        def ==(other)
          other.list == list
        end

        protected

        attr_accessor :list
      end
    end
  end
end
