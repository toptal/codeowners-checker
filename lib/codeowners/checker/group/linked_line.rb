# frozen_string_literal: true

require_relative 'line'

module Codeowners
  class Checker
    class Group
      # It sorts lines from CODEOWNERS file to different line types and holds
      # shared methods for all lines.
      class LinkedLine < Line

        def initialize content, linked_to
          @linked_to = linked_to
          super(content)
        end

        def remove!
          super
          @linked_to&.remove(self)
          @linked_to = nil
        end
      end
    end
  end
end

require_relative 'empty'
require_relative 'comment'
require_relative 'pattern'
require_relative 'unrecognized_line'
