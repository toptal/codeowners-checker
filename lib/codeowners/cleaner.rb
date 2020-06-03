# frozen_string_literal: true

require 'git'
require 'logger'

require_relative 'checker/code_owners'
require_relative 'checker/file_as_array'
require_relative 'checker/whitelist'

module Codeowners
  # Cleans a codeowner file by sorting, grouping and removing
  # useless patterns, all automatically
  class Cleaner
    # Get repo metadata and compare with the owners
    def initialize(repo)
      @git = Git.open(repo, log: Logger.new(IO::NULL))
      @repo_dir = repo
    end

    def clean!
      extract_patterns!
      normalize_patterns!
      remove_duplicates!
      remove_useless!
      group_and_persist!
    end

    def hash_of_arrays
      Hash.new { |h, k| h[k] = [] }
    end

    def pattern_has_files(pattern)
      @git.ls_files(pattern.gsub(%r{^/}, '')).reject(&whitelist).any?
    end

    def file_manager
      @file_manager ||= Checker::FileAsArray.new(Checker::CodeOwners.filename(@repo_dir))
    end

    def whitelist_filename
      @whitelist_filename ||= Checker::CodeOwners.filename(@repo_dir) + '_WHITELIST'
    end

    def whitelist
      @whitelist ||= Checker::Whitelist.new(whitelist_filename)
    end

    private

    def extract_patterns!
      @patterns = Checker::CodeOwners.new(file_manager).main_group.select(&:pattern?)
    end

    def normalize_patterns!
      @patterns.each { |line| line.owners = line.owners.sort }
    end

    def remove_duplicates!
      @patterns.uniq! { |line| [line.pattern, *line.owners] }
    end

    def remove_useless!
      @patterns.select! { |line| pattern_has_files(line.pattern) }
    end

    def group_and_persist!
      new_file_lines =
        @patterns
        .group_by(&:owners)
        .sort_by { |owners, _lines| owners }
        .map { |owners, lines| group_to_string(owners, lines) }
        .join("\n\n")

      file_manager.content = new_file_lines
      file_manager.persist!
    end

    def group_to_string(owners, lines)
      [
        "# Owned by #{owners.join(' ')}",
        *lines.sort_by(&:pattern).map(&:to_s)
      ].join("\n")
    end
  end
end
