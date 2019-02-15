# frozen_string_literal: true

module Codeowners
  class Checker
    module Array
      def safe_delete(object)
        delete_at(index { |item| item.equal?(object) })
      end
    end
  end
end

Array.prepend(Codeowners::Checker::Array)
