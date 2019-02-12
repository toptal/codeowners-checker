# frozen_string_literal: true

require 'code/ownership/checker/group/line'
require 'code/ownership/checker/group'

module Code
  module Ownership
    class Checker
      class LineGrouper
        def initialize(group, lines)
          @group_buffer = [group]
          @lines = lines
        end

        def call
          lines.each_with_index do |line, index|
            case line
            when Code::Ownership::Checker::Group::Empty
              ensure_groups_structure
            when Code::Ownership::Checker::Group::GroupBeginComment
              trim_groups(line.level)
              create_groups_structure(line.level)
            when Code::Ownership::Checker::Group::GroupEndComment
              trim_subgroups(line.level)
              create_groups_structure(line.level)
            when Code::Ownership::Checker::Group::Comment
              if previous_line_empty?(index)
                trim_groups(line.level)
              else
                trim_subgroups(line.level)
              end
              create_groups_structure(line.level)
            when Code::Ownership::Checker::Group::Pattern
              if new_owner?(line, index)
                trim_groups(current_level)
                new_group
              end
              ensure_groups_structure
            when Code::Ownership::Checker::Group::UnrecognizedLine
              ensure_groups_structure
            else
              raise "Do not know how to handle line: #{line.inspect}"
            end
            current_group.add(line)
          end
          group_buffer.first
        end

        private

        attr_reader :group_buffer, :lines

        def previous_line_empty?(index)
          index.positive? && lines[index - 1].is_a?(Code::Ownership::Checker::Group::Empty)
        end

        def new_owner?(line, index)
          if previous_line_empty?(index)
            offset = 2
            while (index - offset).positive?
              case lines[index - offset]
              when Code::Ownership::Checker::Group::GroupEndComment
                nil
              when Code::Ownership::Checker::Group::Comment
                return false
              when Code::Ownership::Checker::Group::Pattern
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
          group = Group.new
          current_group.add(group)
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
end