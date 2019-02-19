# frozen_string_literal: true

module Codeowners
  class Checker
    # Array.delete in contrary to Ruby documentation uses == instead of equal? for comparison.
    # safe_delete removes an object from an array comparing objects by equal? method.
    module Array
      def safe_delete(object)
        delete_at(index { |item| item.equal?(object) })
      end
    end
  end
end

Array.prepend(Codeowners::Checker::Array)
