# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Interactive mode' do
  it 'runs without reporting' do
    expect_not_to_puts
    start
  end
end
