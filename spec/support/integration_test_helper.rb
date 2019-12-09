# frozen_string_literal: true

module IntegrationTestHelper
  # NOTE: due to hight usage of plain #puts we can't rely on RSpec output matcher
  def expect_to_puts(str)
    expect(STDOUT).to receive(:puts).with(str).and_call_original
  end

  def expect_not_to_puts
    expect(STDOUT).not_to receive(:puts)
  end

  def project_fixture_path(name)
    File.join('spec', 'fixtures', 'projects', name)
  end
end
