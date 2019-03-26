# frozen_string_literal: true

module Codeowners
  class Checker
    module Owner
      def self.valid?(*owners)
        owners.any? && owners.all? { |owner| owner.include?('@') }
      end
    end
  end
end
