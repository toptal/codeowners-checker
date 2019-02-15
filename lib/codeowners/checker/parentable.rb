# frozen_string_literal: true

module Codeowners
  class Checker
    module Parentable
      attr_accessor :parent_group, :parent_file

      def remove!
        parent_group&.remove(self)
        parent_file&.remove(self)

        self.parent_group = self.parent_file = nil
      end
    end
  end
end
