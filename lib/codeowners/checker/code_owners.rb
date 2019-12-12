# frozen_string_literal: true

require_relative 'group'
require_relative 'array'

module Codeowners
  class Checker
    # Manage CODEOWNERS file reading and re-writing.
    class CodeOwners
      include Enumerable

      attr_reader :file_manager

      def initialize(file_manager)
        @file_manager = file_manager
      end

      def persist!
        file_manager.content = main_group.to_file
        file_manager.persist!
      end

      def main_group
        @main_group ||= Group.parse(list)
      end

      def each(&block)
        main_group.each(&block)
      end

      def to_content
        main_group.to_content
      end

      def self.filename(repo_dir)
        directories = ['', '.github', 'docs', '.gitlab']
        paths = directories.map { |dir| File.join(repo_dir, dir, 'CODEOWNERS') }
        Dir.glob(paths).first || paths.first
      end

      def filename
        @file_manager.filename
      end

      private

      def list
        @list ||= @file_manager.content.flat_map { |line| build_line(line) }.compact
      end

      def build_line(line)
        Codeowners::Checker::Group::Line.build(line)
      end
    end
  end
end
