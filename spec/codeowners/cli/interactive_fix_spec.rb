# frozen_string_literal: true

RSpec.describe Codeowners::Cli::InteractiveFix do
  include_context 'when main cli handler setup'

  describe '#suggest_add_to_codeowners' do
    let(:new_file) { 'test.rb' }
    let(:patterns_list) do
      checker.main_group.send(:list)
    end
    let(:pattern_added) do
      patterns_list.first.instance_variable_get(:@line)
    end
    let(:main_handler_content_changed_flag) do
      main_handler.send(:content_changed)
    end

    context 'when (y)es answer' do
      let(:add_to_codeowners_question_message) { 'Add to the end of the CODEOWNERS file?' }

      before do
        allow(interactive_fix).to receive(:add_to_codeowners_dialog).with(new_file)
                                                                    .and_return(ask_yes_selection)
      end

      context 'when developer selects default owner' do
        let(:pattern_expected) { "#{new_file} #{default_owner}" }

        before do
          allow(owners_list_handler).to receive(:ask).with(new_owner_ask_title).and_return(default_owner)
        end

        include_context 'when successful add owner behavior'
      end

      context 'when developer adds new owner' do
        let(:pattern_expected) { "#{new_file} #{new_owner}" }

        before do
          allow(owners_list_handler).to receive(:ask).with(new_owner_ask_title).and_return(new_owner)
        end

        include_context 'when successful add owner behavior'
      end
    end

    context 'when (i)gnore answer' do
      let(:ask_selection) { 'i' }

      include_context 'when new file skipped'
    end

    context 'when (q)uit answer' do
      let(:ask_selection) { 'q' }

      before do
        allow(interactive_fix).to receive(:throw).with(:user_quit).and_return(nil)
      end

      include_context 'when new file skipped'
    end
  end
end
