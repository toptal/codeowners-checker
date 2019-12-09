# frozen_string_literal: true

require_relative 'interactive_resolver'
require_relative 'interactive_ops'

module Codeowners
  module Cli
    # Interactive session to resolve codeowners list issues
    class InteractiveRunner
      include InteractiveOps

      attr_writer :validate_owners, :default_owner, :autocommit

      def run_with(checker)
        resolver = InteractiveResolver.new(checker, @validate_owners, @default_owner)
        checker.transformers << resolver.method(:process_parsed_line)
        checker.fix!.each do |(error_type, inconsistencies)|
          resolver.handle(error_type, inconsistencies)
        end
        resolver.print_epilogue
        return unless resolver.made_changes?

        write_changes(checker)
        checker.commit_changes! if @autocommit || yes?('Commit changes?')
      end

      private

      def write_changes(checker)
        checker.codeowners.persist!
        checker.owners_list.persist!
      end
    end
  end
end
