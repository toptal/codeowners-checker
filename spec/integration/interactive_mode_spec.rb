# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Interactive mode' do
  subject(:runner) do
    IntegrationTestRunner
      .new(codeowners: codeowners, owners: owners, file_tree: file_tree, answers: answers)
      .run
  end

  let(:codeowners) { [] }
  let(:owners) { [] }
  let(:file_tree) { {} }
  let(:answers) { [] }

  context 'when no issues' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it { is_expected.to have_empty_report }
  end

  context 'when user_quit is pressed' do
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }
    let(:answers) { ['q'] }

    it 'asks about missing owner file' do
      expect(runner).to ask(<<~QUESTION)
        File added: "lib/new_file.rb". Add owner to the CODEOWNERS file?
        (y) yes
        (i) ignore
        (q) quit and save
      QUESTION
    end
  end

  context 'when missing_ref issue' do
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'asks about missing owner file' do
      expect(runner).to ask(<<~QUESTION)
        File added: "lib/new_file.rb". Add owner to the CODEOWNERS file?
        (y) yes
        (i) ignore
        (q) quit and save
      QUESTION
    end
  end

  context 'when useless_pattern issue' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov', 'liba/* @mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'ask to edit useless paterns from codeowners' do
      expect(runner).to ask(<<~QUESTION).limited_to(%w[i e d q])
        (e) edit the pattern
        (d) delete the pattern
        (i) ignore
        (q) quit and save
      QUESTION
    end

    context 'with fzf installed' do
      def expect_to_run_fzf_suggestion(with_pattern:)
        search_mock = instance_double('Codeowners::Cli::FilesFromFZFSearch')
        expect(Codeowners::Cli::FilesFromFZFSearch).to receive(:new).with(with_pattern) { search_mock }
        expect(search_mock).to receive(:pick_suggestions) { yield }
      end

      before { allow(Codeowners::Cli::SuggestFileFromPattern).to receive(:installed_fzf?).and_return(true) }

      it 'ask to edit useless paterns with suggestion from codeowners' do
        expect_to_run_fzf_suggestion(with_pattern: 'liba/*') { 'lib/' }
        expect(runner).to ask(<<~QUESTION).limited_to(%w[y i e d q])
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

  context 'when invalid_owner issue' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov @foobar'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'asks to add new owner to owners' do
      expect(runner).to ask(<<~QUESTION)
        Unknown owner: @foobar for pattern: lib/new_file.rb. Add owner to the OWNERS file?
        (y) yes
        (i) ignore owner in this session
        (q) quit and save
      QUESTION
    end
  end

  context 'when unrecognized_line issue' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov', '@mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'asks to edit or delete unrecognized lines' do
      expect(runner).to ask(<<~QUESTION).limited_to(%w[y i d])
        "@mpospelov" is in unrecognized format. Would you like to edit?
        (y) yes
        (i) ignore
        (d) delete the line
      QUESTION
    end
  end
end
