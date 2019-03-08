# frozen_string_literal: true

require_relative 'group'
require_relative 'array'

module Codeowners
  class Checker
    # Manage CODEOWNERS file reading and re-writing.
    class CodeOwners
      include Enumerable

      attr_reader :file_manager, :transform_line_procs

      def initialize(file_manager, transformers: nil)
        @file_manager = file_manager
        @transform_line_procs = [
          method(:build_line),
          *transformers
        ]
      end

      def persist!
        file_manager.content = main_group.to_file
      end

      def main_group
        @main_group ||= Group.parse(list)
      end

      def each(&block)
        main_group.each(&block)
      end

      def to_content
        main_group.to_content
      end

      private

      def list
        @list ||= @file_manager.content.yield_self do |list|
          transform_line_procs.each do |transform_line_proc|
            list = list.flat_map { |line| transform_line_proc.call(line) }.compact
          end
          list
        end
      end

      def build_line(line)
        Codeowners::Checker::Group::Line.build(line)
      end
    end
  end
end
