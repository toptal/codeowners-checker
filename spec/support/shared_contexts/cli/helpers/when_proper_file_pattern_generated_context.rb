# frozen_string_literal: true

require 'spec_helper'

shared_context 'when proper file pattern generated' do
  let(:pattern) { select_owner_dialog.pattern }
  let(:pattern_line) { pattern.instance_variable_get(:@line) }
  let(:pattern_expected) { "#{new_file} #{default_owner}" }

  it 'returns proper pattern object' do
    expect(pattern).to be_kind_of(Codeowners::Checker::Group::Pattern)
    expect(pattern_line).to eq(pattern_expected)
  end
end
