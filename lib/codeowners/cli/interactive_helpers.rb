module Codeowners
  module Cli
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
