# frozen_string_literal: true

module Codeowners
  module Cli

    # Case the user have `fzf` installed, it works building suggestions from
    # `fzf`. See more on #fzf_query.
    #
    # Without `fzf` it tries to suggest patterns using fuzzy match search picking
    # all the files from the parent folder of the current pattern.
    class SuggestionBuilder
      def initialize(pattern)
        @pattern =  pattern
      end

      # Pick suggestion from current pattern
      # If have fzf installed, pick suggestions using fzf
      # otherwise fallback to the default fuzzy match searching for the file
      # from the parent folder.
      def pick_suggestion
        strategy_class.new(@pattern).pick_suggestions
      end

      def strategy_class
        installed_fzf? ? FilesFromFZFSearch : FilesFromParentFolder
      end

      # Checks if fzf is installed.
      def installed_fzf?
        `command -v fzf` != ''
      end
    end

    # Build a list of suggestions case the pattern is not matching.
    class SuggestionStrategy
      def initialize(pattern)
        @pattern = pattern
      end

      def pick_suggestions
        raise NotImplementedError.new
      end
    end

    class FilesFromFZFSearch < SuggestionStrategy
      # Bring a list of suggestions using `fzf` from the current folder
      def pick_suggestions
        `fzf --height 50% --reverse -q #{query.inspect}`
          .lines.first&.chomp
      end

      # Returns shortcut of the current folders
      #
      # => 'some/folder/with/file.txt' to 'some/fowi/file.txt'
      #
      def query
        dir, _, file = @pattern.gsub(/[_\-\*]+/, '').rpartition '/'
        dir.gsub(%r{/(\w{,2})[^/]+}, '\1') + # map 2 chars per folder
          file.gsub(/\.\w+/, '')             # remove extension
      end
    end

    # Pick all files from parent folder of pattern.
    # Apply fuzzy match search on all files to pick the best option.
    class FilesFromParentFolder < SuggestionStrategy
      # Filter for files using fuzzy match search against all the files from
      # the parent folder.
      def pick_suggestions
        require 'fuzzy_match'
        search = FuzzyMatch.new(suggest_files_for_pattern)
        search.find(@pattern)
      end
      # If the pattern use "*/*" it will consider "."
      # If the pattern uses Static files, it tries to reach the parent.
      # If the pattern revers to the root folder, pick all files from the
      # current pattern dir.
      def query
        parent_folders = @pattern.split('/')[0..-2]
        parent_folders << '*' if parent_folders[-1] != '*'
        File.join(*parent_folders)
      end

      private

      def suggest_files_for_pattern
        files = Dir[query] || []
        files.map(&method(:normalize_path))
      end

      def normalize_path(file)
        Pathname.new(file)
                .relative_path_from(Pathname.new('.')).to_s
      end
    end
  end
end
