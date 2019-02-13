# frozen_string_literal: true

require_relative '../checker'
require_relative 'base'

module Code
  module Ownership
    module Cli
      # List changed files. Provide an option to list all the changed files grouped by
      # the owner of the file or filter them and show only the files owned by default owner.
      class Filter < Base
        option :from, default: 'origin/master'
        option :to, default: 'HEAD'
        option :verbose, default: false, type: :boolean, aliases: '-v'
        desc 'by <owner>', <<~DESC
          Lists changed files owned by owner.
          If no owner is specified, default owner is taken from the config file.
        DESC
        # option :local, default: false, type: :boolean, aliases: '-l'
        # option :branch, default: '', aliases: '-b'
        def by(owner = config.default_owner)
          return if owner.empty?

          changes = checker.changes_with_ownership(owner)
          if changes.key?(owner)
            changes.values.each { |file| puts file }
          else
            puts "Owner #{owner} not defined in .github/CODEOWNERS"
          end
        end

        option :from, default: 'origin/master'
        option :to, default: 'HEAD'
        option :verbose, default: false, type: :boolean, aliases: '-v'
        desc 'all', 'Lists all changed files grouped by owner'
        def all
          changes = checker.changes_with_ownership.select { |_owner, val| val && !val.empty? }
          changes.keys.each do |owner|
            puts(owner + ":\n  " + changes[owner].join("\n  ") + "\n\n")
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
          Code::Ownership::Checker.new(@repo_base_path, options[:from], options[:to])
        end
      end
    end
  end
end
