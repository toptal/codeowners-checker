# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Interactive mode' do
  it 'runs with no-issues reporting' do
    start(
      codeowners: ['lib/new_file.rb @mpospelov'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_not_to_puts
    end
  end

  it 'runs with missing_ref issue' do
    start(file_tree: { 'lib/new_file.rb' => 'bar' }) do
      expect_to_ask(<<~QUESTION)
        File added: "lib/new_file.rb". Add owner to the CODEOWNERS file?
        (y) yes
        (i) ignore
        (q) quit and save
      QUESTION
    end
  end

  it 'runs with useless_pattern issue' do
    start(
      codeowners: ['lib/new_file.rb @mpospelov', 'liba/* @mpospelov'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_ask(<<~QUESTION, limited_to: %w[i e d q])
        (e) edit the pattern
        (d) delete the pattern
        (i) ignore
        (q) quit and save
      QUESTION
    end
  end

  it 'runs with invalid_owner issue' do
    start(
      codeowners: ['lib/new_file.rb @foobar'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_ask(<<~QUESTION)
        Unknown owner: @foobar for pattern: lib/new_file.rb. Add owner to the OWNERS file?
        (y) yes
        (i) ignore owner in this session
        (q) quit and save
      QUESTION
    end
  end

  it 'runs with unrecognized_line issue' do
    start(
      codeowners: ['lib/new_file.rb @mpospelov', '@mpospelov'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_ask(<<~QUESTION, limited_to: %w[y i d])
        "@mpospelov" is in unrecognized format. Would you like to edit?
        (y) yes
        (i) ignore
        (d) delete the line
      QUESTION
    end
  end

  context 'with fzf installed' do
    def expect_to_run_fzf_suggestion(with_pattern:)
      search_mock = instance_double('Codeowners::Cli::FilesFromFZFSearch')
      expect(Codeowners::Cli::FilesFromFZFSearch).to receive(:new).with(with_pattern) { search_mock }
      expect(search_mock).to receive(:pick_suggestions) { yield }
    end

    before { allow(Codeowners::Cli::SuggestFileFromPattern).to receive(:installed_fzf?).and_return(true) }

    it 'runs with useless_pattern issue' do
      start(
        codeowners: ['lib/new_file.rb @mpospelov', 'liba/* @mpospelov'],
        owners: ['@mpospelov'],
        file_tree: { 'lib/new_file.rb' => 'bar' }
      ) do
        expect_to_run_fzf_suggestion(with_pattern: 'liba/*') { 'lib/' }
        expect_to_ask(<<~QUESTION, limited_to: %w[y i e d q])
          Replace with: "lib/"?
          (y) yes
          (i) ignore
          (e) edit the pattern
          (d) delete the pattern
          (q) quit and save
        QUESTION
      end
    end
  end
end
