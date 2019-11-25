# frozen_string_literal: true

RSpec.describe Codeowners::Cli::InteractiveFix do
  let(:interactive_fix) { described_class.new }
  let(:cli_content_changed_flag) { interactive_fix.content_changed }
  let(:new_file) { 'new_file.rb' }

  describe '#suggest_add_to_codeowners' do
    before do
      allow(interactive_fix).to receive(:add_to_codeowners_dialog).with(new_file).and_return(ask_selection)
    end

    context 'when (y)es answer' do
      let(:ask_selection) { 'y' }

      before do
        allow(interactive_fix).to receive(:add_to_codeowners)
      end

      it 'calls #add_to_codeowners with new_file' do
        interactive_fix.suggest_add_to_codeowners(new_file)
        expect(interactive_fix).to have_received(:add_to_codeowners).with(new_file)
      end
    end

    context 'when (i)gnore answer' do
      let(:ask_selection) { 'i' }

      it 'skips new file' do
        interactive_fix.suggest_add_to_codeowners(new_file)
        expect(interactive_fix).not_to receive(:add_to_codeowners)
      end
    end

    context 'when (q)uit answer' do
      let(:ask_selection) { 'q' }

      before do
        allow(interactive_fix).to receive(:throw).with(:user_quit).and_return(nil)
      end

      it 'skips new file' do
        interactive_fix.suggest_add_to_codeowners(new_file)
        expect(interactive_fix).not_to receive(:add_to_codeowners)
      end
    end
  end

  describe '#add_to_codeowners_dialog' do
    before do
      allow(interactive_fix).to receive(:ask)
    end

    it 'asks to add owner to the CODEOWNERS file' do
      interactive_fix.__send__(:add_to_codeowners_dialog, new_file)

      expect(interactive_fix).to have_received(:ask).with(<<~QUESTION, limited_to: %w[y i q])
        File added: #{new_file.inspect}. Add owner to the CODEOWNERS file?
        (y) yes
        (i) ignore
        (q) quit and save
      QUESTION
    end
  end

  describe '#add_to_codeowners' do
    let(:assign_file_owner_class) { Codeowners::Cli::Helpers::AssignFileOwner }
    let(:add_pattern_into_group_class) { Codeowners::Cli::Helpers::AddPatternIntoGroup }

    before do
      allow(assign_file_owner_class).to receive_message_chain(:new, :pattern) # rubocop:disable RSpec/MessageChain
      allow(add_pattern_into_group_class).to receive_message_chain(:new, :run) # rubocop:disable RSpec/MessageChain
    end

    it 'initiates AssignFileOwner, AddPatternIntoGroup and triggers @content_changed flag' do
      interactive_fix.__send__(:add_to_codeowners, new_file)

      expect(assign_file_owner_class).to have_received(:new)
      expect(add_pattern_into_group_class).to have_received(:new)
      expect(cli_content_changed_flag).to be_truthy
    end
  end
end
