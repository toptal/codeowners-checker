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
        attach_resolver(resolver, checker)
        checker.fix!
        resolver.print_epilogue
        return unless resolver.made_changes?

        write_changes(checker)
        checker.commit_changes! if @autocommit || yes?('Commit changes?')
      end

      private

      def attach_resolver(resolver, checker)
        checker.when_useless_pattern = resolver.method(:handle_useless_pattern)
        checker.when_new_file = resolver.method(:handle_new_file)
        checker.transformers << resolver.method(:process_parsed_line)
        checker.owners_list.when_new_owner = resolver.method(:handle_new_owner)
      end

      def write_changes(checker)
        checker.codeowners.persist!
        checker.owners_list.persist!
      end
    end
  end
end
