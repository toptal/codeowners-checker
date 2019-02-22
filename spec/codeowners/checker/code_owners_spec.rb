# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require 'codeowners/checker/code_owners'

RSpec.describe Codeowners::Checker::CodeOwners do
  subject { described_class.new(file_manager) }

  let(:file_manager) { double }

  let(:example_content) do
    [
      '#comment1',
      '',
      '',
      '#group1',
      '#comment1',
      'pattern @owner',
      'pattern2 @owner',
      'pattern @owner',
      ''
    ]
  end

  describe '#initialize' do
    it 'parses the content into groups of lines and builds the list back from groups' do
      expect(file_manager).to receive(:content).and_return(example_content)
      expect(subject.to_content).to eq(example_content)
    end
  end
end
