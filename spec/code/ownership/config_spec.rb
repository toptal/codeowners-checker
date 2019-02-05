# frozen_string_literal: true

require 'code/ownership/config'

RSpec.describe Code::Ownership::Config do
  subject { described_class.new fake_git }

  let(:fake_git) { double }

  describe '#default_team' do
    it 'picks default user.team from git configuration' do
      expect(fake_git).to receive('config').with('user.team').and_return('')
      expect(subject.default_team).to be_empty
    end
  end

  describe '#default_team=' do
    it 'sets default user.team from git configuration' do
      expect(fake_git).to receive('config').with('user.team', 'my-team')
      subject.default_team = 'my-team'
    end
  end

  describe '#to_h' do
    it 'converts default_team to a hash' do
      expect(fake_git).to receive('config').with('user.team').and_return('my-team')
      expect(subject.to_h).to eq(default_team: 'my-team')
    end
  end
end
