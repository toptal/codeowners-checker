# frozen_string_literal: true

require_relative 'group'
require_relative 'array'

module Codeowners
  class Checker
    # Manage CODEOWNERS file reading and re-writing.
    class CodeOwners
      attr_reader :list, :file_manager, :transform_line_procs

      def initialize(file_manager, transform_line_procs: nil)
        @file_manager = file_manager
        @transform_line_procs = [
          method(:build_line),
          *(transform_line_procs || []),
          method(:assign_line_parent)
        ]
        parse_file
      end

      def persist!
        file_manager.content = to_content
      end

      def remove(content)
        @list.safe_delete(content)
      end

      def insert_after(previous_line, line)
        return if @list.include?(line)

        previous_index = @list.index(previous_line)
        index = previous_index ? previous_index + 1 : 0

        line.parent_file = self
        @list.insert(index, line)
      end

      def to_content
        @list.map(&:to_content)
      end

      private

      def parse_file
        @list = @file_manager.content

        transform_line_procs.each do |transform_line_proc|
          @list = @list.flat_map { |line| transform_line_proc.call(line) }.compact
        end

        @list
      end

      def build_line(line)
        Codeowners::Checker::Group::Line.build(line)
      end

      def assign_line_parent(line)
        line.parent_file = self
        line
      end
    end
  end
end
