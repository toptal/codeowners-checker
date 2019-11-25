# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Helpers::AssignFileOwner do
  let(:owner_assigner) { described_class.new(interactive_fix, new_file) }
  let(:interactive_fix) { Codeowners::Cli::InteractiveFix.new }

  include_context 'when owners prepared'
  include_context 'when new file pattern prepared'
  include_context 'when checker for cli prepared'

  describe '#run' do
    let(:options) { {} }
    let(:owners_list_handler) { Codeowners::Cli::OwnersListHandler.new }
    let(:owners) { owner_assigner.__send__(:owners) }

    before do
      allow(interactive_fix).to receive(:owners_list_handler).and_return(owners_list_handler)
      allow(interactive_fix).to receive(:checker).and_return(checker)
      allow(interactive_fix).to receive(:options).and_return(options)
      allow(owner_assigner).to receive(:show_existing_owners)
    end

    context 'when \'validate owners\' mode turned on' do
      let(:options) { { validateowners: true } }

      before do
        allow(owners_list_handler).to receive(:create_new_pattern_with_validated_owner).and_return(pattern)
        allow(owners_list_handler).to receive(:create_new_pattern_with_owner)
      end

      it 'tries to create new pattern with validation of owner' do
        output = owner_assigner.pattern

        expect(output).to be(pattern)
        expect(owner_assigner).to have_received(:show_existing_owners)
        expect(owners_list_handler).to have_received(:create_new_pattern_with_validated_owner).with(new_file, owners)
        expect(owners_list_handler).not_to have_received(:create_new_pattern_with_owner)
      end
    end

    context 'when \'validate owners\' mode turned off' do
      before do
        allow(owners_list_handler).to receive(:create_new_pattern_with_owner).and_return(pattern)
        allow(owners_list_handler).to receive(:create_new_pattern_with_validated_owner)
      end

      it 'tries to create new pattern without validation of owner' do
        output = owner_assigner.pattern

        expect(output).to be(pattern)
        expect(owner_assigner).to have_received(:show_existing_owners)
        expect(owners_list_handler).to have_received(:create_new_pattern_with_owner).with(new_file, owners)
        expect(owners_list_handler).not_to have_received(:create_new_pattern_with_validated_owner)
      end
    end
  end

  describe '#show_existing_owners' do
    let(:existing_owners) do
      [default_owner, frontend_owner]
    end
    let(:existing_owners_output) do
      owner_assigner.__send__(:show_existing_owners)
    end

    before do
      # rubocop:disable RSpec/MessageChain
      allow(owner_assigner).to receive_message_chain('config.default_owner') { default_owner }
      # rubocop:enable RSpec/MessageChain
      allow(owner_assigner).to receive(:owners).and_return(existing_owners)
    end

    it 'shows list of existing owners' do
      expect { existing_owners_output }.to output(<<~MESSAGE).to_stdout
        Owners:
        1 - #{default_owner}
        2 - #{frontend_owner}
        Choose owner, add new one or leave empty to use "#{default_owner}".
      MESSAGE
    end
  end
end
