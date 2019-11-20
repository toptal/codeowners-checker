# frozen_string_literal: true

require 'spec_helper'

shared_context 'when main cli handler setup' do
  let(:main_handler) do
    inst = Codeowners::Cli::Main.new

    inst.options = options
    inst.instance_variable_set(:@config, config)
    inst.instance_variable_set(:@checker, checker)
    inst.instance_variable_set(:@owners_list_handler, owners_list_handler)

    inst
  end
  let(:options) { {} }
  let(:config) do
    conf = Codeowners::Cli::Config.new
    conf.owner(default_owner)

    conf.config
  end
  let(:default_owner) { '@toptal/bootcamp' }
  let(:new_owner) { '@toptal/ninjas' }
  let(:folder_name) { '.' }
  let(:from) { 'HEAD' }
  let(:to) { 'HEAD' }
  let(:checker) { Codeowners::Checker.new(folder_name, from, to) }
  let(:owners_list_handler) { Codeowners::Cli::OwnersListHandler.new }
  let(:interactive_fix) do
    inst = Codeowners::Cli::InteractiveFix.new
    inst.main_handler = main_handler

    inst
  end
  let(:ask_yes_selection) { 'y' }
  let(:new_owner_ask_title) { 'New owner: ' }

  before do
    main_handler.instance_variable_set(:@interactive_fix, interactive_fix)
    owners_list_handler.instance_variable_set(:@checker, checker)
  end
end
