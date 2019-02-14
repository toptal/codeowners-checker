# frozen_string_literal: true

require 'codeowners/config'

RSpec.describe Codeowners::Config do
  subject { described_class.new fake_git }

  let(:fake_git) { double }

  describe '#default_owner' do
    it 'picks default user.owner from git configuration' do
      expect(fake_git).to receive('config').with('user.owner').and_return('')
      expect(subject.default_owner).to be_empty
    end
  end

  describe '#default_owner=' do
    it 'sets default user.team from git configuration' do
      expect(fake_git).to receive('config').with('user.owner', 'my-team')
      subject.default_owner = 'my-team'
    end
  end

  describe '#to_h' do
    it 'converts default_owner to a hash' do
      expect(fake_git).to receive('config').with('user.owner').and_return('my-team')
      expect(subject.to_h).to eq(default_owner: 'my-team')
    end
  end
end
