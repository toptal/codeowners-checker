# frozen_string_literal: true

shared_context 'when owners prepared' do
  let(:company) { '@company' }
  let(:default_owner) { "#{company}/backend" }
  let(:frontend_owner) { "#{company}/frontend" }
end
