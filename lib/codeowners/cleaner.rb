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
    def initialize(repo)
      @git = Git.open(repo, log: Logger.new(IO::NULL))
      @filename = Checker::CodeOwners.filename(repo)
    end

    # Performs the cleanup, rewriting the CODEOWNERS file
    #
    # It runs the following changes:
    # - "Normalizes" everyline by removing duplicate owners and sorting them
    # - Removes duplicated lines (only full duplicates)
    # - Removes lines without any matching files
    #
    # After these steps are done, it:
    # - Groups the lines by owners
    # - Writes them to the CODEOWNERS file with a comment about the owners
    def clean!
      patterns =
        extract_patterns
        .map { |p| normalized_line(p) }
        .uniq { |p| line_id(p) }
        .select { |p| line_pattern_has_files(p) }

      group_and_persist!(patterns)
    end

    def file_manager
      @file_manager ||= Checker::FileAsArray.new(@filename)
    end

    def whitelist_filename
      @whitelist_filename ||= @filename + '_WHITELIST'
    end

    def whitelist
      @whitelist ||= Checker::Whitelist.new(whitelist_filename)
    end

    private

    def extract_patterns
      Checker::CodeOwners.new(file_manager).main_group.select(&:pattern?)
    end

    def line_pattern_has_files(line)
      @git.ls_files(line.pattern.gsub(%r{^/}, '')).reject(&whitelist).any?
    end

    def line_id(line)
      [line.pattern, *line.owners]
    end

    def normalized_line(line)
      line = line.clone
      line.owners = line.owners.uniq.sort
      line
    end

    def group_and_persist!(lines)
      file_manager.content = group_and_render(lines)
      file_manager.persist!
    end

    def group_and_render(lines)
      lines
        .group_by(&:owners)
        .sort_by { |owners, _lines| owners }
        .map { |owners, group_lines| group_to_string(owners, group_lines) }
        .join("\n\n")
    end

    def group_to_string(owners, lines)
      [
        "# Owned by #{owners.join(' ')}",
        *lines.sort_by(&:pattern).map(&:to_s)
      ].join("\n")
    end
  end
end
