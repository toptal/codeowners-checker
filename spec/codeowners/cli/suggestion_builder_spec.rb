# frozen_string_literal: true

RSpec.describe Codeowners::Cli::SuggestionBuilder do
  subject { described_class.new(line) }

  let(:line) { 'file/not/found @owner' }

  describe '.pick_suggestions' do
    context 'when have fzf installed' do
      before { allow(subject).to receive(:installed_fzf?).and_return(true) }

      it 'suggest with fzf' do
        expect(subject).to receive(:suggest_with_fzf).and_return(['line'])
        subject.pick_suggestion
      end
    end

    context 'without fzf' do
      before { allow(subject).to receive(:installed_fzf?).and_return(false) }

      it 'suggests with FuzzyMatch gem' do
        expect(subject).to receive(:suggest_with_fuzzy_match).and_return(['line'])
        subject.pick_suggestion
      end
    end
  end

  describe '#fuzzy_match_query' do
    context 'with multiple stars' do
      let(:line) { 'app/*/*' }

      it 'ignore multiple stars' do
        expect(subject.fuzzy_match_query).to eq('app/*')
      end
    end

    context 'with single star in the end' do
      let(:line) { 'app/*' }

      it 'keeps the query' do
        expect(subject.fuzzy_match_query).to eq('app/*')
      end
    end

    context 'with double star combining with pattern' do
      let(:line) { 'spec/*/*_spec.rb' }

      it 'generalize to the parent folder' do
        expect(subject.fuzzy_match_query).to eq('spec/*')
      end
    end

    context 'with deep folder specification' do
      let(:line) { 'a/very/long/sub/folder/to/file.txt' }

      it 'generalize to the parent folder' do
        expect(subject.fuzzy_match_query).to eq('a/very/long/sub/folder/to/*')
      end
    end
  end

  describe '#fzf_query' do
    context 'with deep folder specification' do
      let(:line) { 'a/very/long/folder/to_file.txt' }

      it 'creates shortcuts with the first two chars of each folder' do
        expect(subject.fzf_query).to eq('avelofotofile')
      end
    end

    context 'with double star combining with pattern' do
      let(:line) { 'spec/models/*/*_spec.rb' }

      it 'generalize to query' do
        expect(subject.fzf_query).to eq('specmo/spec')
      end
    end
  end
end
