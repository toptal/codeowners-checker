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
              new_group if current_level.zero?
            when Code::Ownership::Checker::Group::GroupBeginComment
              trim_groups(line.level)
              new_group
            when Code::Ownership::Checker::Group::GroupEndComment
              trim_subgroups(line.level)
              new_group if current_level < line.level
            when Code::Ownership::Checker::Group::Comment
              if previous_line_empty?(index)
                trim_groups(line.level)
              else
                trim_subgroups(line.level)
              end
              new_group if current_level < line.level
            when Code::Ownership::Checker::Group::Pattern, Code::Ownership::Checker::Group::UnrecognizedLine
              new_group if current_level.zero?
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
