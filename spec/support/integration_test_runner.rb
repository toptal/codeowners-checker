# frozen_string_literal: true

require_relative 'helpers'

class IntegrationTestRunner
  include RSpec::Mocks::ExampleMethods
  include Helpers

  # Silence thor warnings while setting up io listeners
  class CaptureIO < StringIO
    def puts(text)
      super unless text.start_with?('[WARNING] Attempted to create command')
    end
  end

  Result = Struct.new(:reports, :warnings, :questions)
  PROJECT_PATH = File.join('tmp', 'test-project')

  def initialize(codeowners: [], owners: [], file_tree: {}, flags: [], answers: [])
    @codeowners = codeowners
    @owners = owners
    @file_tree = file_tree
    @flags = flags.tap { |f| f.push('--from=HEAD~1') }
    @answers = answers
    @reports = []
    @warnings = []
    @questions = []
  end

  # rubocop: disable Lint/HandleExceptions
  def run(command: 'check', flags: @flags)
    setup_project
    $stdout = CaptureIO.new
    setup_io_listeners
    $stdout = STDOUT
    begin
      Codeowners::Cli::Main.start([command, PROJECT_PATH, *flags])
    rescue SystemExit
    end
    Result.new(@reports.flatten, @warnings, @questions)
  end
  # rubocop: enable Lint/HandleExceptions

  class << self
    def assert_matcher_input(input)
      raise ArgumentError, "instance of #{Result} is expected, but got #{input.class}" unless input.is_a?(Result)
    end
  end

  private

  attr_reader :codeowners, :owners, :file_tree, :flags

  # rubocop: disable Metrics/AbcSize
  # rubocop: disable Metrics/MethodLength
  def setup_project
    Dir.mkdir('tmp') unless Dir.exist?('tmp')
    remove_dir(PROJECT_PATH)
    on_dirpath(PROJECT_PATH) do
      Git.init
      git = Git.open('.', logger: Logger.new(STDOUT))
      Dir.mkdir('.github')
      File.write(File.join('.github', 'CODEOWNERS'), codeowners.join("\n"))
      File.write(File.join('.github', 'OWNERS'), owners.join("\n"))
      git.add(all: true)
      git.commit('First commit :yay:')
      create_file_tree
      git.add(all: true)
      git.commit('File tree created')
    end
  end
  # rubocop: enable Metrics/AbcSize
  # rubocop: enable Metrics/MethodLength

  def create_file_tree
    file_tree.each do |file_path, content|
      unless File.exist?(file_path)
        parts = file_path.split('/')
        dir_parts = parts[0..-2]
        create_dir(File.join(*dir_parts)) unless dir_parts.empty?
      end
      File.write(file_path, content)
    end
  end

  # rubocop: disable Metrics/AbcSize
  # rubocop: disable RSpec/AnyInstance
  def setup_io_listeners
    allow(Codeowners::Reporter).to receive(:print) { |*args| @reports << args }
    allow(Codeowners::Cli::Warner).to receive(:warn) { |msg| @warnings << msg }
    allow_any_instance_of(Thor).to receive(:ask) do |_, question, limited_to|
      @questions << [question, limited_to].compact
      @answers.shift
    end
    allow_any_instance_of(Thor).to receive(:yes?) do |_, question|
      @questions << [question]
      @answers.shift
    end
  end
  # rubocop: enable RSpec/AnyInstance
  # rubocop: enable Metrics/AbcSize

  RSpec::Matchers.define :warn_with do |*expected_warnings|
    match do |result|
      IntegrationTestRunner.assert_matcher_input(result)
      expected_warnings.join("\n") == result.warnings.join("\n")
    end

    failure_message do |actual|
      <<~MSG
        expected that the warnings:

        #{actual.warnings.map { |w| "- #{w}" }.join("\n")}

        will include all of:

        #{expected_warnings.map { |w| "- #{w}" }.join("\n")}
      MSG
    end
  end

  RSpec::Matchers.define :report_with do |*expected_reports|
    match do |result|
      IntegrationTestRunner.assert_matcher_input(result)
      expected_reports.join("\n") == result.reports.join("\n")
    end

    failure_message do |actual|
      <<~MSG
        expected that the report:

        #{actual.reports.map { |r| "- #{r}" }.join("\n")}

        will include all of:

        #{expected_reports.map { |r| "- #{r}" }.join("\n")}"
      MSG
    end
  end

  RSpec::Matchers.define :have_empty_report do
    match do |result|
      IntegrationTestRunner.assert_matcher_input(result)
      result.reports.empty? && result.questions.empty?
    end

    failure_message do |actual|
      <<~MSG
        expected that the report will be empty, but it includes:

        #{actual.reports.map { |r| "- #{r}" }.join("\n")}
      MSG
    end
  end

  RSpec::Matchers.define :ask do |question|
    match do |result|
      IntegrationTestRunner.assert_matcher_input(result)

      if @limited_to
        result.questions.include?([question, limited_to: @limited_to])
      else
        result.questions.include?([question])
      end
    end

    chain :limited_to do |limited_to|
      @limited_to = limited_to
    end

    failure_message do |actual|
      <<~MSG
        expected that the the following will questions:

        #{actual.questions.map { |(q, limited_to)| "#{limited_to}\n#{q}" }.join("\n")}

        will include:

        #{{ limited_to: @limited_to }}
        #{question}
      MSG
    end
  end
end
