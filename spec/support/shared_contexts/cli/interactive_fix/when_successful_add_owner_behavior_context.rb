# frozen_string_literal: true

require 'spec_helper'

shared_context 'when successful add owner behavior' do
  before do
    allow(interactive_fix).to receive(:yes?).with(add_to_codeowners_question_message).and_return(true)
    interactive_fix.suggest_add_to_codeowners(new_file)
  end

  it 'adds pattern for new file and triggers content_changed flag for main_handler' do
    expect(pattern_added).to eq(pattern_expected)
    expect(main_handler_content_changed_flag).to be_truthy
  end
end
