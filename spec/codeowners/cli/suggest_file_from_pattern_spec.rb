# frozen_string_literal: true

RSpec.describe Codeowners::Cli::SuggestFileFromPattern do
  subject { described_class.new(line) }

  let(:line) { 'file/not/found @owner' }

  describe '#strategy' do
    context 'when have fzf installed' do
      before { allow(described_class).to receive(:installed_fzf?).and_return(true) }

      it 'suggest with fzf' do
        expect(subject.strategy_class).to eq(Codeowners::Cli::FilesFromFZFSearch)
      end
    end

    context 'without fzf' do
      before { allow(described_class).to receive(:installed_fzf?).and_return(false) }

      it 'suggests with FuzzyMatch gem' do
        expect(subject.strategy_class).to eq(Codeowners::Cli::FilesFromParentFolder)
      end
    end
  end

  describe Codeowners::Cli::FilesFromParentFolder do
    context 'with multiple stars' do
      let(:line) { 'app/*/*' }

      it 'ignore multiple stars' do
        expect(subject.query).to eq('app/*')
      end
    end

    context 'with single star in the end' do
      let(:line) { 'app/*' }

      it 'keeps the query' do
        expect(subject.query).to eq('app/*')
      end
    end

    context 'with double star combining with pattern' do
      let(:line) { 'spec/*/*_spec.rb' }

      it 'generalize to the parent folder' do
        expect(subject.query).to eq('spec/*')
      end
    end

    context 'with deep folder specification' do
      let(:line) { 'a/very/long/sub/folder/to/file.txt' }

      it 'generalize to the parent folder' do
        expect(subject.query).to eq('a/very/long/sub/folder/to/*')
      end
    end
  end

  describe Codeowners::Cli::FilesFromFZFSearch do
    context 'with deep folder specification' do
      let(:line) { 'a/very/long/folder/to_file.txt' }

      it 'creates shortcuts with the first two chars of each folder' do
        expect(subject.query).to eq('avelofotofile')
      end
    end

    context 'with double star combining with pattern' do
      let(:line) { 'spec/models/*/*_spec.rb' }

      it 'generalize to query' do
        expect(subject.query).to eq('specmo/spec')
      end
    end
  end
end
