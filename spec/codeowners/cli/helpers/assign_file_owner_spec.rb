# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Helpers::AssignFileOwner do
  include_context 'when main cli handler setup'

  let(:new_file) { 'test.rb' }
  let(:select_owner_dialog) do
    described_class.new(interactive_fix, new_file)
  end

  describe '#run' do
    let(:owners) do
      select_owner_dialog.send(:owners)
    end

    before do
      allow(owners_list_handler).to receive(:ask).with(new_owner_ask_title).and_return(default_owner)
      allow(owners_list_handler).to receive(:add_to_ownerslist_dialog).and_return(ask_yes_selection)
    end

    context 'when validateowners mode turned on' do
      before do
        main_handler.options = { validateowners: true }
      end

      it 'tries to create new pattern with validation of owner' do
        expect(select_owner_dialog).to receive(:show_existing_owners)
        expect(owners_list_handler).to receive(:create_new_pattern_with_validated_owner).with(new_file, owners)

        select_owner_dialog.pattern
      end

      include_context 'when proper file pattern generated'
    end

    context 'when validateowners mode turned off' do
      it 'tries to create new pattern without validation of owner' do
        expect(select_owner_dialog).to receive(:show_existing_owners)
        expect(owners_list_handler).to receive(:create_new_pattern_with_owner).with(new_file, owners)

        select_owner_dialog.pattern
      end

      include_context 'when proper file pattern generated'
    end
  end

  describe '#show_existing_owners' do
    let(:existing_owners) do
      [default_owner, new_owner]
    end
    let(:existing_owners_output) do
      select_owner_dialog.send(:show_existing_owners)
    end

    before do
      allow(select_owner_dialog).to receive(:owners).and_return(existing_owners)
    end

    it 'shows list of existing owners' do
      expect { existing_owners_output }.to output(<<~MESSAGE).to_stdout
        Owners:
        1 - #{default_owner}
        2 - #{new_owner}
        Choose owner, add new one or leave empty to use "#{default_owner}".
      MESSAGE
    end
  end
end
