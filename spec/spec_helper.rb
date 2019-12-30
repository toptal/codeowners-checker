# frozen_string_literal: true

require 'pry'
require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'bundler/setup'
require 'codeowners/cli/main'
Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |file| require file }

Dir['lib/**/*.rb'].each { |file| require file[4..-1] }

RSpec.configure do |config|
  config.include Helpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    ENV['GITHUB_ORGANIZATION'] = ''
    ENV['GITHUB_TOKEN'] = nil
  end
end
