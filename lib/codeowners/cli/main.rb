# frozen_string_literal: true

require_relative '../checker'
require_relative '../reporter'
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
        Warner.warn("No whitelist found at #{checker.whitelist_filename}") unless
          checker.whitelist?

        if checker.consistent?
          Reporter.print '✅ File is consistent'
          exit 0
        end

        options[:interactive] ? interactive_mode(checker) : report_inconsistencies(checker)

        exit(-1)
      end

      desc 'cleanup REPO', 'Automatically fixes some issues and rewrite .github/CODEOWNERS in a specific order'
      def cleanup(repo = '.')
        checker = create_checker(repo)
        Warner.warn("No whitelist found at #{checker.whitelist_filename}") unless
          checker.whitelist?

        new_file_lines =
          checker
          .main_group
          .select { |item| item.instance_of?(Codeowners::Checker::Group::Pattern) }
          .each{|pattern| pattern.owners = pattern.owners.sort}
          .uniq {|pattern| [pattern.pattern, *pattern.owners]}
          .group_by { |pattern| pattern.owners }
          .sort_by { |owners, _patterns| owners }
          .map do |owners, patterns|
            [
              "# Owned by #{owners.join(' ')}",
              *patterns.sort_by(&:pattern).map(&:to_s)
            ].join("\n")
          end
          .join("\n\n")

        checker.codeowners.file_manager.content = new_file_lines
        checker.codeowners.file_manager.persist!

        if checker.consistent?
          Reporter.print '✅ File is consistent'
          exit 0
        end

        exit(-1)
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
        Reporter.print "File #{checker.codeowners.filename} is inconsistent:"
        report_errors!(checker)
      end

      def create_checker(repo)
        from = options[:from]
        to = options[:to] != 'index' ? options[:to] : nil
        checker = Codeowners::Checker.new(repo, from, to)
        checker.owners_list.validate_owners = options[:validateowners]
        checker
      end

      def report_errors!(checker)
        checker.fix!.reduce(nil) do |prev_error_type, (error_type, inconsistencies, meta)|
          Reporter.print_delimiter_line(error_type) if prev_error_type != error_type
          Reporter.print_error(error_type, inconsistencies, meta)
          error_type
        end
      end
    end
  end
end
