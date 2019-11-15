# frozen_string_literal: true

module Codeowners
  module Cli
    # Helpers for the CLI (ask) and (yes) methods
    module InteractiveHelpers
      def ask(message, *opts)
        return unless options[:interactive]

        super
      end

      def yes?(message, *opts)
        return unless options[:interactive]

        super
      end
    end
  end
end
