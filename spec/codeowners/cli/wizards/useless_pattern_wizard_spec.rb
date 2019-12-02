# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Wizards::UselessPatternWizard do
  let(:wizard) { described_class.new }
  let(:suggester) { instance_double(Codeowners::Cli::SuggestFileFromPattern) }
  let(:suggestion) { nil }

  before do
    allow(Codeowners::Cli::SuggestFileFromPattern).to receive(:new).and_return(suggester)
    allow(suggester).to receive(:pick_suggestion).and_return(suggestion)
  end

  describe '#suggest_fixing' do
    let(:useless_pattern) { Codeowners::Checker::Group::Pattern.new('some/useless/pattern/*.rb @ownerX') }
    let(:error_message) { 'Pattern "some/useless/pattern/*.rb" doesn\'t match.' }
    let(:suggested_pattern) { 'suggested/pattern/*.rb' }
    let(:edited_pattern) { 'edited/pattern/*.rb' }

    before do
      allow(wizard).to receive(:puts).with(error_message)
    end

    it 'outputs error message' do
      allow(wizard).to receive(:ask)

      wizard.suggest_fixing(useless_pattern)

      expect(wizard).to have_received(:puts).with(error_message)
    end

    shared_examples 'basic editor' do
      let(:prompt) { '' }
      let(:prompt_options) { '' }

      it 'prompts with suggestion' do
        allow(wizard).to receive(:ask)

        wizard.suggest_fixing(useless_pattern)

        expect(wizard).to have_received(:ask).with(prompt, limited_to: prompt_options)
      end

      context 'when the user chose to ignore' do
        before do
          allow(wizard).to receive(:ask).and_return('i')
        end

        it 'returns :ignore' do
          choice = wizard.suggest_fixing(useless_pattern)

          expect(choice).to be(:ignore)
        end
      end

      context 'when the user chose to edit the pattern' do
        before do
          allow(wizard).to receive(:ask).and_return('e', edited_pattern)
        end

        it 'prompts for new pattern and returns [:replace, edited_pattern]' do
          choice, new_pattern = wizard.suggest_fixing(useless_pattern)

          expect(wizard).to have_received(:ask).with(prompt, limited_to: prompt_options).ordered
          expect(wizard).to have_received(:ask).with('Replace pattern "some/useless/pattern/*.rb" with: ').ordered
          expect(choice).to be(:replace)
          expect(new_pattern).to eq(edited_pattern)
        end
      end

      context 'when the user chose to delete the pattern' do
        before do
          allow(wizard).to receive(:ask).and_return('d')
        end

        it 'returns :delete' do
          choice = wizard.suggest_fixing(useless_pattern)

          expect(choice).to be(:delete)
        end
      end

      context 'when the user chose to quit' do
        before do
          allow(wizard).to receive(:ask).and_return('q')
        end

        it 'returns :quit' do
          choice = wizard.suggest_fixing(useless_pattern)

          expect(choice).to be(:quit)
        end
      end
    end

    context 'when suggestion is available' do
      let(:suggestion) { suggested_pattern }

      it_behaves_like 'basic editor' do
        let(:prompt) { <<~QUESTION }
          Replace with: "suggested/pattern/*.rb"?
          (y) yes
          (i) ignore
          (e) edit the pattern
          (d) delete the pattern
          (q) quit and save
        QUESTION
        let(:prompt_options) { %w[y i e d q] }
      end

      context 'when the user chose to replace' do
        before do
          allow(wizard).to receive(:ask).and_return('y')
        end

        it 'returns [:replace, suggested_pattern]' do
          choice, new_pattern = wizard.suggest_fixing(useless_pattern)

          expect(choice).to be(:replace)
          expect(new_pattern).to eq(suggested_pattern)
        end
      end
    end

    context 'when suggestion is not available' do
      let(:suggestion) { nil }

      it_behaves_like 'basic editor' do
        let(:prompt) { <<~QUESTION }
          (e) edit the pattern
          (d) delete the pattern
          (i) ignore
          (q) quit and save
        QUESTION
        let(:prompt_options) { %w[i e d q] }
      end
    end
  end
end
