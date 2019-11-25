# frozen_string_literal: true

RSpec.describe Codeowners::Cli::OwnersListHandler do
  let(:owners_list_handler) { described_class.new }

  describe '#suggest_add_to_owners_list' do
    let(:new_file) { 'test.rb' }
    let(:the_owner) { '@owner1' }
    let(:another_owner1) { '@owner2' }
    let(:another_owner2) { '@owner3' }
    let(:line_str) { "#{new_file} #{the_owner}" }
    let(:line) { Codeowners::Checker::Group::Line.build(line_str) }

    before do
      allow(owners_list_handler).to receive(:add_to_ownerslist_dialog)
    end

    context 'when ignored list is empty' do
      it 'calls #add_to_ownerslist_dialog' do
        owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list_handler).to have_received(:add_to_ownerslist_dialog).with(line, the_owner)
      end
    end

    context 'when ignored list contains provided owner' do
      let(:ingored_owners) { [another_owner1, the_owner] }

      before do
        allow(owners_list_handler).to receive(:ignored_owners).and_return(ingored_owners)
      end

      it 'does not call #add_to_ownerslist_dialog and return nil' do
        output = owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(output).to be_nil
        expect(owners_list_handler).not_to have_received(:add_to_ownerslist_dialog).with(line, the_owner)
      end
    end

    context 'when ignored list does not contain provided owner' do
      let(:ingored_owners) { [another_owner1, another_owner2] }

      before do
        allow(owners_list_handler).to receive(:ignored_owners).and_return(ingored_owners)
      end

      it 'calls #add_to_ownerslist_dialog' do
        owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list_handler).to have_received(:add_to_ownerslist_dialog).with(line, the_owner)
      end
    end

    context 'when user chooses to ignore owner' do
      before do
        allow(owners_list_handler).to receive(:add_to_ownerslist_dialog).and_return('i')
      end

      it 'adds it to ignored_owners and returns nil' do
        output = owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(output).to be_nil
        expect(owners_list_handler.ignored_owners).to include(the_owner)
      end
    end

    context 'when user chooses to add owner' do
      before do
        allow(owners_list_handler).to receive(:add_to_ownerslist)
        allow(owners_list_handler).to receive(:add_to_ownerslist_dialog).and_return('y')
      end

      it 'calls #add_to_ownerslist and does not add it to ignored_owners' do
        owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list_handler).to have_received(:add_to_ownerslist).with(the_owner)
        expect(owners_list_handler.ignored_owners).not_to include(the_owner)
      end
    end

    context 'when user chooses to quit' do
      before do
        allow(owners_list_handler).to receive(:add_to_ownerslist_dialog).and_return('q')
      end

      it 'throws :user_quit and does not add it to ignored_owners' do
        expect { owners_list_handler.suggest_add_to_owners_list(line, the_owner) }.to throw_symbol :user_quit
        expect(owners_list_handler.ignored_owners).not_to include(the_owner)
      end
    end
  end
end
