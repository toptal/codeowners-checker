# frozen_string_literal: true

module Codeowners
  module Cli
    # List files owned by the given owner
    class List < Base
      option :from, default: 'origin/master'
      option :to, default: 'HEAD'
      option :verbose, default: false, type: :boolean, aliases: '-v'
      desc 'by <owner>', <<~DESC
        Lists all files owned by owner.
        If no owner is specified, default owner is taken from the config file.
      DESC
      # option :local, default: false, type: :boolean, aliases: '-l'
      # option :branch, default: '', aliases: '-b'
      def by(owner = config.default_owner)
        return if owner.empty?

        Reporter.print "Checking ownership for '#{owner}'"
        results = checker.list_files_for_owner(owner)
        if results
          print_results(results)
        else
          Reporter.print "Owner #{owner} not defined in .github/CODEOWNERS"
        end
      end

      def initialize(args = [], options = {}, config = {})
        super
        @repo_base_path = `git rev-parse --show-toplevel`
        if !@repo_base_path || @repo_base_path.empty?
          raise 'You must be positioned in a git repository to use this tool'
        end

        @repo_base_path.chomp!
        Dir.chdir(@repo_base_path)

        @checker ||= config[:checker] || default_checker
      end

      default_task :by

      private

      attr_reader :checker

      def default_checker
        Codeowners::Checker.new(@repo_base_path, options[:from], options[:to])
      end

      def print_results(results)
        results.each do |pattern, files|
          Reporter.print "Pattern: '#{pattern}' - matches #{files.length} file(s)"
          if options[:verbose]
            files.each { |name| Reporter.print "\t#{name}" }
            Reporter.print '*' * 30
          end
        end
      end
    end
  end
end
