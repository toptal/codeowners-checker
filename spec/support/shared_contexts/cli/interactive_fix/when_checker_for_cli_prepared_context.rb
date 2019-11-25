# frozen_string_literal: true

shared_context 'when checker for cli prepared' do
  let(:folder_name) { '.' }
  let(:checker) { Codeowners::Checker.new(folder_name) }

  before do
    allow(interactive_fix).to receive(:checker).and_return(checker)
  end
end
