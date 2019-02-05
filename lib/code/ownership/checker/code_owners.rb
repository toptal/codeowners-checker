# frozen_string_literal: true

require 'code/ownership/checker/group'
require 'code/ownership/checker/group/comment'

module Code
  module Ownership
    class Checker
      class CodeOwners < Group
        def parse_file(new_file_manager = nil)
          file_manager = new_file_manager
          lines = file_manager.content.map(&Code::Ownership::Checker::Group::Line.method(:build))
          # TODO: ask the user to fix unrecognized lines?
          parse(lines)
        end

        def persist!(new_file_manager = nil)
          file_manager = new_file_manager
          file_manager.content = to_content
        end

        private

        # TODO: raise exception if no @file_manager
        attr_reader :file_manager

        def file_manager=(file_manager)
          raise ArgumentError, '' if file_manager.nil? && @file_manager.nil?

          @file_manager = file_manager if file_manager
        end
      end
    end
  end
end
