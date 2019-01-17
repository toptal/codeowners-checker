# frozen_string_literal: true

RSpec.describe Code::Ownership::Config do
  subject { described_class.new fake_git }

  let(:fake_git) do
    double
  end

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
end
