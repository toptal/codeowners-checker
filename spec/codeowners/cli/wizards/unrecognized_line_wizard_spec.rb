# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Wizards::UnrecognizedLineWizard do
  let(:wizard) { described_class.new }

  describe '#suggest_fixing' do
    let(:unrecognized_line) { Codeowners::Checker::Group::UnrecognizedLine.new('some unrecognized line') }
    let(:valid_string) { 'some/file.rb @ownerX' }
    let(:invalid_string) { 'some invalid string' }
    let(:suggestion) { <<~QUESTION }
      "some unrecognized line" is in unrecognized format. Would you like to edit?
      (y) yes
      (i) ignore
      (d) delete the line
    QUESTION
    let(:suggestion_options) { %w[y i d] }

    it 'suggest fixing the line' do
      allow(wizard).to receive(:ask)

      wizard.suggest_fixing(unrecognized_line)

      expect(wizard).to have_received(:ask).with(suggestion, limited_to: suggestion_options)
    end

    context 'when the user chose to edit' do
      let(:user_input_line) { '' }
      let(:user_input_another_line) { '' }

      before do
        allow(wizard).to receive(:ask).and_return('y', user_input_line, user_input_another_line)
      end

      it 'prompts for new line' do
        wizard.suggest_fixing(unrecognized_line)

        expect(wizard).to have_received(:ask).with(suggestion, limited_to: suggestion_options).ordered
        expect(wizard).to have_received(:ask).with('New line: ').ordered
      end

      context 'when the user inputs valid line' do
        let(:user_input_line) { valid_string }

        it 'returns [:replace, new_line]' do
          choice, new_line = wizard.suggest_fixing(unrecognized_line)

          expect(wizard).to have_received(:ask).with(suggestion, limited_to: suggestion_options).ordered
          expect(wizard).to have_received(:ask).with('New line: ').ordered
          expect(choice).to be(:replace)
          expect(new_line).to be_a(Codeowners::Checker::Group::Line)
          expect(new_line.to_s).to eq(valid_string)
        end
      end

      context 'when the user inputs invalid line' do
        let(:user_input_line) { invalid_string }

        it 'asks again' do
          wizard.suggest_fixing(unrecognized_line)

          expect(wizard).to have_received(:ask).with(suggestion, limited_to: suggestion_options).ordered
          expect(wizard).to have_received(:ask).with('New line: ').twice.ordered
        end
      end

      context 'when the user inputs valid line after invalid one' do
        let(:user_input_line) { invalid_string }
        let(:user_input_another_line) { valid_string }

        it 'returns new line and marks content change' do
          choice, new_line = wizard.suggest_fixing(unrecognized_line)

          expect(wizard).to have_received(:ask).with(suggestion, limited_to: suggestion_options).ordered
          expect(wizard).to have_received(:ask).with('New line: ').twice.ordered
          expect(choice).to be(:replace)
          expect(new_line).to be_a(Codeowners::Checker::Group::Line)
          expect(new_line.to_s).to eq(valid_string)
        end
      end
    end

    context 'when the user chose to ignore' do
      before do
        allow(wizard).to receive(:ask).and_return('i')
      end

      it 'returns :ignore' do
        choice = wizard.suggest_fixing(unrecognized_line)

        expect(choice).to be(:ignore)
      end
    end

    context 'when the user chose to delete' do
      before do
        allow(wizard).to receive(:ask).and_return('d')
      end

      it 'returns nil' do
        choice = wizard.suggest_fixing(unrecognized_line)

        expect(choice).to be(:delete)
      end
    end
  end
end
