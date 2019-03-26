# frozen_string_literal: true

module Codeowners
  module Cli
    # Build a list of suggestions case the pattern is not matching.
    #
    # Case the user have `fzf` installed, it works building suggestions from
    # `fzf`. See more on #fzf_query.
    #
    # Without `fzf` it tries to suggest patterns using fuzzy match search picking
    # all the files from the parent folder of the current pattern.
    #
    # See more on #fuzzy_match_query.
    class SuggestionBuilder
      def initialize(pattern)
        @pattern = pattern
      end

      # Pick suggestion from current pattern
      # If have fzf installed, pick suggestions using fzf
      # otherwise fallback to the default fuzzy match searching for the file
      # from the parent folder.
      def pick_suggestion
        return suggest_with_fzf if installed_fzf?

        suggest_with_fuzzy_match
      end

      # Pick all files from parent folder of pattern.
      # If the pattern use "*/*" it will consider "."
      # If the pattern uses Static files, it tries to reach the parent.
      # If the pattern revers to the root folder, pick all files from the
      # current pattern dir.
      def fuzzy_match_query
        parent_folders = @pattern.split('/')[0..-2]
        parent_folders << '*' if parent_folders[-1] != '*'
        File.join(*parent_folders)
      end

      # Returns shortcut of the current folders
      #   SuggestionBuilder.new('some/folder/with/file.txt') # => some/fowi/file.txt
      def fzf_query
        dir, _, file = @pattern.gsub(/[_\-\*]+/, '').rpartition '/'
        dir.gsub(%r{/(\w{,2})[^/]+}, '\1') + # map 2 chars per folder
          file.gsub(/\.\w+/, '')             # remove extension
      end

      private

      # Filter for files using fuzzy match search against all the files from
      # the parent folder.
      def suggest_with_fuzzy_match
        require 'fuzzy_match'
        search = FuzzyMatch.new(suggest_files_for_pattern)
        search.find(@pattern)
      end

      def suggest_files_for_pattern
        files = Dir[fuzzy_match_query] || []
        files.map(&method(:normalize_path))
      end

      # Bring a list of suggestions using `fzf` from the current folder
      def suggest_with_fzf
        `fzf --height 50% --reverse -q #{fzf_query.inspect}`
          .lines.first&.chomp
      end

      # Checks if fzf is installed.
      def installed_fzf?
        `command -v fzf` != ''
      end

      def normalize_path(file)
        Pathname.new(file)
                .relative_path_from(Pathname.new('.')).to_s
      end
    end
  end
end
