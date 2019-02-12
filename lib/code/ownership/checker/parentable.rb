# frozen_string_literal: true

require 'set'

require 'code/ownership/checker/group/line'

module Code
  module Ownership
    class Checker
      module Parentable
        def parents
          @parents ||= Set.new
        end

        def remove!
          parents.each { |parent| parent.remove(self) }
          parents.delete(self)
        end
      end
    end
  end
end
