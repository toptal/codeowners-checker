# frozen_string_literal: true

require 'codeowners/checker/whitelist'

RSpec.describe Codeowners::Checker::Whitelist do
  subject { described_class.new(whitelist_filename) }

  let(:folder_name) { 'project' }
  let(:whitelisted_file)   { 'whitelisted_file.rb' }
  let(:whitelist_filename) { '.github/CODEOWNERS_WHITELIST' }

  around do |example|
    on_dirpath(folder_name) do
      create_dir('.github')
      File.write('.github/CODEOWNERS_WHITELIST', whitelisted_file)
      File.write(whitelisted_file, "# some ruby code here\n")
      example.call
    end
    remove_dir(folder_name)
  end

  context 'when referring to a non-existent whitelist file' do
    let(:whitelist_filename) { 'does-not-exist' }

    it 'returns a whitelist matching nothing' do
      expect(subject.whitelisted?('example.rb')).to be false
    end
  end

  context 'when referring to an existing file' do
    it 'reports true for a path listed in the whitelist' do
      expect(subject.whitelisted?(whitelisted_file)).to be true
    end
  end

  context 'when used as a proc' do
    it 'returns true for whitelisted items' do
      expect([whitelisted_file].all?(&subject)).to be true
    end

    it 'returns false for non-whitelisted items' do
      expect(['example.rb'].all?(&subject)).to be false
    end
  end
end
