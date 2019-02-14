# frozen_string_literal: true

require 'codeowners/checker/group/pattern'

RSpec.describe Codeowners::Checker::Group::Pattern do
  describe '#to_s' do
    subject { described_class.build(line) }

    context 'when one owner' do
      let(:line) { 'pattern @owner' }

      it 'converts pattern and owner to a string' do
        expect(subject.to_s).to eq('pattern @owner')
      end
    end

    context 'when multiple owners' do
      let(:line) { 'pattern @owner @owner1 @owner2' }

      it 'converts pattern and owner to a string' do
        expect(subject.to_s).to eq('pattern @owner @owner1 @owner2')
      end
    end
  end
end
