# frozen_string_literal: true

module Codeowners
  module Cli
    # Provides convenience methods like :ask, :yes? without subclassing Thor
    module InteractiveOps
      def yes?(statement, color = nil)
        thor.yes?(statement, color)
      end

      def ask(statement, *args)
        thor.ask(statement, *args)
      end

      private

      def thor
        @thor ||= Thor.new
      end
    end
  end
end
