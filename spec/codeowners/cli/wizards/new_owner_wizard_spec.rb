# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Wizards::NewOwnerWizard do
  let(:wizard) { described_class.new }

  describe '#suggest_adding' do
    let(:new_file) { 'text.rb' }
    let(:the_owner) { '@owner1' }
    let(:line_str) { "#{new_file} #{the_owner}" }
    let(:line) { Codeowners::Checker::Group::Line.build(line_str) }
    let(:suggestion) { <<~QUESTION }
      Unknown owner: #{the_owner} for pattern: #{new_file}. Add owner to the OWNERS file?
      (y) yes
      (i) ignore owner in this session
      (q) quit and save
    QUESTION
    let(:suggestion_options) { %w[y i q] }
    let(:user_choice) { '' }

    before do
      allow(wizard).to receive(:ask).and_return(user_choice)
    end

    it 'suggests owner addition' do
      wizard.suggest_adding(line, the_owner)

      expect(wizard).to have_received(:ask).with(suggestion, limited_to: suggestion_options)
    end

    context 'when the user chose to add' do
      let(:user_choice) { 'y' }

      it 'returns :add' do
        choice = wizard.suggest_adding(line, the_owner)

        expect(choice).to be(:add)
      end
    end

    context 'when the user chose to ignore' do
      let(:user_choice) { 'i' }

      it 'returns :ignore' do
        choice = wizard.suggest_adding(line, the_owner)

        expect(choice).to be(:ignore)
      end
    end

    context 'when the user chose to quit' do
      let(:user_choice) { 'q' }

      it 'returns :quit' do
        choice = wizard.suggest_adding(line, the_owner)

        expect(choice).to be(:quit)
      end
    end
  end
end
