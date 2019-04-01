# frozen_string_literal: true

module Codeowners
  class Checker
    # Create groups and subgroups structure for the lines in the CODEOWNERS file.
    class LineGrouper
      def self.call(group, lines)
        new(group, lines).call
      end

      def initialize(group, lines)
        @group_buffer = [group]
        @lines = lines
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/MethodLength
      def call
        lines.each_with_index do |line, index|
          case line
          when Codeowners::Checker::Group::Empty
            ensure_groups_structure
          when Codeowners::Checker::Group::GroupBeginComment
            trim_groups(line.level)
            create_groups_structure(line.level)
          when Codeowners::Checker::Group::GroupEndComment
            trim_subgroups(line.level)
            create_groups_structure(line.level)
          when Codeowners::Checker::Group::Comment
            if previous_line_empty?(index)
              trim_groups(line.level)
            else
              trim_subgroups(line.level)
            end
            create_groups_structure(line.level)
          when Codeowners::Checker::Group::Pattern
            if new_owner?(line, index)
              trim_groups(current_level)
              new_group
            end
            ensure_groups_structure
          when Codeowners::Checker::Group::UnrecognizedLine
            ensure_groups_structure
          else
            raise "Do not know how to handle line: #{line.inspect}"
          end
          current_group.add(line)
        end
        group_buffer.first
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength

      private

      attr_reader :group_buffer, :lines

      def previous_line_empty?(index)
        index.positive? && lines[index - 1].is_a?(Codeowners::Checker::Group::Empty)
      end

      def new_owner?(line, index) # rubocop:disable Metrics/MethodLength
        if previous_line_empty?(index)
          offset = 2
          while (index - offset).positive?
            case lines[index - offset]
            when Codeowners::Checker::Group::GroupEndComment
              nil
            when Codeowners::Checker::Group::Comment
              return false
            when Codeowners::Checker::Group::Pattern
              return line.owner != lines[index - offset].owner
            end
            offset += 1
          end
        end
        false
      end

      def current_group
        group_buffer.last
      end

      def current_level
        group_buffer.length - 1
      end

      def new_group
        group = current_group.create_subgroup
        group_buffer << group
      end

      def ensure_groups_structure
        new_group if current_level.zero?
      end

      def create_groups_structure(level)
        new_group while current_level < level
      end

      def trim_groups(level)
        group_buffer.slice!(level..-1)
      end

      def trim_subgroups(level)
        trim_groups(level + 1)
      end
    end
  end
end
