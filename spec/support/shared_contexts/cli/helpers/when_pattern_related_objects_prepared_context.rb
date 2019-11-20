# frozen_string_literal: true

shared_context 'when pattern related objects prepared' do
  let(:new_file) { 'test.rb' }
  let(:new_file_pattern_line) { "#{new_file} #{default_owner}" }
  let(:pattern) do
    Codeowners::Checker::Group::Pattern.new(new_file_pattern_line)
  end
end
