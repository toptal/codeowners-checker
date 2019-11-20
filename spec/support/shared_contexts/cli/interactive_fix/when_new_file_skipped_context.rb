# frozen_string_literal: true

require 'spec_helper'

shared_context 'when new file skipped' do
  before do
    allow(interactive_fix).to receive(:add_to_codeowners_dialog).with(new_file).and_return(ask_selection)
  end

  it 'skips new file' do
    expect(interactive_fix).not_to receive(:add_to_codeowners)
    interactive_fix.suggest_add_to_codeowners(new_file)

    expect(patterns_list).to be_empty
    expect(main_handler_content_changed_flag).to be_falsey
  end
end
