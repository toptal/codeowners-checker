# frozen_string_literal: true

module Codeowners
  class Checker
    module Parentable
      def parents
        @parents ||= Set.new
      end

      def remove!
        parents.each { |parent| parent.remove(self) }
        parents.clear
      end
    end
  end
end
