# frozen_string_literal: true

require 'codeowners/github_fetcher'

RSpec.describe Codeowners::GithubFetcher do
  subject { described_class }

  def mock_response(headers)
    instance_double(RestClient::Response, headers: headers)
  end
  let(:response) { mock_response({}) }

  describe '#next_page' do
    context 'when there is no link in response' do
      it 'returns nil' do
        expect(subject.send(:get_next_page, response)).to eq(nil)
      end
    end

    context 'when there is link in response' do
      let(:headers) { { link: '<https://api.github.com/next/page>; rel="next"' } }
      let(:response) { mock_response(headers) }

      it 'returns the link' do
        expect(subject.send(:get_next_page, response)).to eq('https://api.github.com/next/page')
      end
    end
  end

  describe '#get_owners' do
    let(:expected_response) { ['@github/owner1', '@github/owner2', '@owner1', '@owner2'] }
    let(:response_body) { '[{"slug": "owner1", "login": "owner1"},{"slug": "owner2", "login": "owner2"}]' }
    let(:github_response) { instance_double(RestClient::Response, body: response_body, headers: {}) }

    before do
      allow(RestClient).to receive(:get).and_return(github_response)
      allow(described_class).to receive(:get_headers).and_return(nil)
    end

    it 'returns list of owners' do
      expect(described_class.get_owners('github', 'token')).to eq(expected_response)
    end
  end
end
