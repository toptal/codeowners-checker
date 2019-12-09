# frozen_string_literal: true

require_relative '../checker'
require_relative 'base'
require_relative 'config'
require_relative 'filter'
require_relative 'owners_list_handler'
require_relative '../github_fetcher'
require_relative 'suggest_file_from_pattern'
require_relative '../checker/owner'
require_relative 'interactive_runner'

module Codeowners
  module Cli
    # Command Line Interface used by bin/codeowners-checker.
    class Main < Base
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :interactive, default: true, type: :boolean, aliases: '-i'
      option :validateowners, default: true, type: :boolean, aliases: '-v'
      option :autocommit, default: false, type: :boolean, aliases: '-c'
      desc 'check REPO', 'Checks .github/CODEOWNERS consistency'
      # for pre-commit: --from HEAD --to index
      def check(repo = '.')
        checker = create_checker(repo)
        if options[:interactive]
          interactive_mode(checker)
        else
          report_inconsistencies(checker)
        end
      end

      desc 'filter <by-owner>', 'List owners of changed files'
      subcommand 'filter', Codeowners::Cli::Filter

      desc 'config', 'Checks config is consistent or configure it'
      subcommand 'config', Codeowners::Cli::Config

      desc 'fetch [REPO]', 'Fetches .github/OWNERS based on github organization'
      subcommand 'fetch', Codeowners::Cli::OwnersListHandler

      private

      def interactive_mode(checker)
        runner = InteractiveRunner.new
        runner.validate_owners = options[:validateowners]
        runner.default_owner = @config.default_owner
        runner.autocommit = options[:autocommit]

        runner.run_with(checker)
      end

      def report_inconsistencies(checker)
        if checker.consistent?
          puts '✅ File is consistent'
          exit 0
        else
          puts "File #{checker.codeowners.filename} is inconsistent:"
          report_errors!(checker)
          exit(-1)
        end
      end

      def create_checker(repo)
        from = options[:from]
        to = options[:to] != 'index' ? options[:to] : nil
        checker = Codeowners::Checker.new(repo, from, to)
        checker.owners_list.validate_owners = options[:validateowners]
        checker
      end

      LABELS = {
        missing_ref: 'No owner defined',
        useless_pattern: 'Useless patterns',
        invalid_owner: 'Invalid owner',
        unrecognized_line: 'Unrecognized line'
      }.freeze

      def report_errors!(checker)
        checker.fix!.group_by { |(error_type)| error_type }.each do |error_type, group|
          puts LABELS[error_type], '-' * 30, group.map { |(_, inconsistencies)| inconsistencies }, '-' * 30
        end
      end
    end
  end
end
