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

  describe '#default_organization' do
    before do
      allow(fake_git).to receive('config').with('remote.origin.url').and_return(remote_url)
    end

    let(:remote_url) { 'git@github.com:toptal/codeowners-checker.git' }

    context 'without user.organization set' do
      before do
        allow(fake_git).to receive('config').with('user.organization').and_return(nil)
      end

      it 'calls git config and fetches remote origin information' do
        expect(fake_git).to receive('config').with('remote.origin.url')
        subject.default_organization
      end

      it 'guesses default organization by using the origin url' do
        expect(subject.default_organization).to eq('toptal')
      end

      context 'with empty user.organization' do
        before do
          allow(fake_git).to receive('config').with('user.organization').and_return(' ')
        end

        it 'guesses default organization by using the origin url' do
          expect(subject.default_organization).to eq('toptal')
        end
      end

      context 'without a remote origin' do
        let(:remote_url) { nil }

        it 'returns blank string' do
          expect(subject.default_organization).to eq('')
        end
      end

      context 'without a parseable organization' do
        let(:remote_url) { 'git@github.com:codeowners-checker.git' }

        it 'returns blank string' do
          expect(subject.default_organization).to eq('')
        end
      end
    end

    context 'with user.organization set' do
      before do
        allow(fake_git).to receive('config').with('user.organization').and_return('other-org')
      end

      it 'does not call git config to fetch remote origin information' do
        expect(fake_git).not_to receive('config').with('remote.origin.url')
        subject.default_organization
      end

      it 'uses the value set for user.organization instead of guessing' do
        expect(subject.default_organization).to eq('other-org')
      end
    end
  end

  describe '#default_organization=' do
    it 'sets default user.team from git configuration' do
      expect(fake_git).to receive('config').with('user.organization', 'toptal')
      subject.default_organization = 'toptal'
    end
  end

  describe '#to_h' do
    before do
      allow(subject).to receive(:default_owner).and_return('my-team')
      allow(subject).to receive(:default_organization).and_return('toptal')
    end

    it 'converts default_owner to a hash' do
      expect(subject.to_h).to eq(default_owner: 'my-team', default_organization: 'toptal')
    end
  end
end
