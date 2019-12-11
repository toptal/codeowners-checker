# frozen_string_literal: true

class IntegrationTestRunner
  include RSpec::Mocks::ExampleMethods

  Result = Struct.new(:reports, :questions)
  PROJECT_PATH = File.join('tmp', 'test-project')

  def initialize(codeowners: [], owners: [], file_tree: {}, flags: [], answers: [])
    @codeowners = codeowners
    @owners = owners
    @file_tree = file_tree
    @flags = flags.tap { |f| f.push('--from=HEAD~1') }
    @answers = answers
    @reports = []
    @questions = []
  end

  # rubocop: disable Lint/HandleExceptions
  def run
    setup_project
    setup_io_listeners
    begin
      Codeowners::Cli::Main.start(['check', PROJECT_PATH, *flags])
    rescue SystemExit
    end
    Result.new(@reports.flatten, @questions)
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
    FileUtils.rm_r(PROJECT_PATH) if Dir.exist?(PROJECT_PATH)
    Dir.mkdir(PROJECT_PATH)
    Dir.chdir(PROJECT_PATH) do
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
        FileUtils.mkdir_p(File.join(*dir_parts)) unless dir_parts.empty?
      end
      File.write(file_path, content)
    end
  end

  # rubocop: disable RSpec/AnyInstance
  def setup_io_listeners
    allow(Codeowners::Reporter).to receive(:print) { |*args| @reports << args }
    allow_any_instance_of(Thor).to receive(:ask) do |_, question, limited_to|
      @questions << [question, limited_to]
      @answers.shift
    end
  end
  # rubocop: enable RSpec/AnyInstance

  RSpec::Matchers.define :report_with do |*expected_reports|
    match do |result|
      IntegrationTestRunner.assert_matcher_input(result)
      expected_reports.all? { |r| result.reports.include?(r) }
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

        will include all of:

        #{expected_reports.map { |r| "- #{r}" }.join("\n")}"
      MSG
    end
  end

  RSpec::Matchers.define :ask do |question|
    match do |result|
      IntegrationTestRunner.assert_matcher_input(result)
      @limited_to ||= %w[y i q]
      result.questions.include?([question, limited_to: @limited_to])
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
