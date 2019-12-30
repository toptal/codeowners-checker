# frozen_string_literal: true

module Codeowners
  module Cli
    # Checks and prints deprecation warnings.
    module Warner
      class << self
        def check_warnings
          check_github_env
        end

        def warn(msg)
          puts "[WARNING] #{msg}"
        end

        protected

        def check_github_env
          return if ENV['GITHUB_ORGANIZATION'].nil? || ENV['GITHUB_ORGANIZATION'].empty?

          warn 'Usage of GITHUB_ORGANIZATION ENV variable has been deprecated.'\
            'Run `codeowners-checker config organization #{organization}` instead.'
        end
      end
    end
  end
end
