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
      let(:ignored_owners) { [another_owner1, the_owner] }

      before do
        allow(owners_list_handler).to receive(:ignored_owners).and_return(ignored_owners)
      end

      it 'does not call #add_to_ownerslist_dialog and return nil' do
        output = owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(output).to be_nil
        expect(owners_list_handler).not_to have_received(:add_to_ownerslist_dialog).with(line, the_owner)
      end
    end

    context 'when ignored list does not contain provided owner' do
      let(:ignored_owners) { [another_owner1, another_owner2] }

      before do
        allow(owners_list_handler).to receive(:ignored_owners).and_return(ignored_owners)
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

  describe '#suggest_add_to_owners_list' do
    let(:new_file) { 'text.rb' }
    let(:the_owner) { '@owner1' }
    let(:another_owner1) { '@owner2' }
    let(:another_owner2) { '@owner3' }
    let(:line_str) { "#{new_file} #{the_owner}" }
    let(:line) { Codeowners::Checker::Group::Line.build(line_str) }
    let(:suggestion) { <<~QUESTION }
      Unknown owner: #{the_owner} for pattern: #{new_file}. Add owner to the OWNERS file?
      (y) yes
      (i) ignore owner in this session
      (q) quit and save
    QUESTION
    let(:suggestion_options) { %w[y i q] }
    let(:owners_list) { instance_double(::Array, 'owners_list') }
    let(:checker) { instance_double(Codeowners::Checker, 'checker') }

    before do
      allow(owners_list).to receive(:<<)
      allow(checker).to receive(:owners_list).and_return(owners_list)
    end

    shared_examples 'provided owner is not ignored' do
      before do
        owners_list_handler.ignored_owners.push(*original_ignored_owners)
      end

      it 'suggest owner addition' do
        allow(owners_list_handler).to receive(:ask)

        owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list_handler).to have_received(:ask).with(suggestion, limited_to: suggestion_options)
      end

      it 'updates owners list if user chooses to add' do
        allow(owners_list_handler).to receive(:ask).and_return('y')
        owners_list_handler.checker = checker

        output = owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list).to have_received(:<<).with(the_owner)
        expect(owners_list_handler.content_changed).to be_truthy
        expect(owners_list_handler.ignored_owners).not_to include(the_owner)
        expect(output).to be_truthy
      end

      it 'update ignored owners and returns nil if user chooses to ignore' do
        allow(owners_list_handler).to receive(:ask).and_return('i')
        owners_list_handler.checker = checker

        output = owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list).not_to have_received(:<<)
        expect(owners_list_handler.content_changed).not_to be_truthy
        expect(owners_list_handler.ignored_owners).to include(the_owner)
        expect(output).to be_nil
      end

      it 'throws :user_quit and does not change anything' do
        allow(owners_list_handler).to receive(:ask).and_return('q')
        owners_list_handler.checker = checker

        expect { owners_list_handler.suggest_add_to_owners_list(line, the_owner) }.to throw_symbol :user_quit

        expect(owners_list).not_to have_received(:<<)
        expect(owners_list_handler.content_changed).not_to be_truthy
        expect(owners_list_handler.ignored_owners).not_to include(the_owner)
      end
    end

    context 'when ignored owners list is empty' do
      it_behaves_like 'provided owner is not ignored' do
        let(:original_ignored_owners) { [] }
      end
    end

    context 'when ignored owners list does not contain provided owner' do
      it_behaves_like 'provided owner is not ignored' do
        let(:original_ignored_owners) { [another_owner1, another_owner2] }
      end
    end

    context 'when ignore owners list contains provided owner' do
      let(:original_ignored_owners) { [another_owner1, the_owner, another_owner2] }

      before do
        owners_list_handler.ignored_owners.push(*original_ignored_owners)
      end

      it 'does nothing and returns nil' do
        allow(owners_list_handler).to receive(:ask)
        owners_list_handler.checker = checker

        output = owners_list_handler.suggest_add_to_owners_list(line, the_owner)

        expect(owners_list_handler).not_to have_received(:ask)
        expect(owners_list_handler.content_changed).not_to be_truthy
        expect(owners_list_handler.ignored_owners).to eq(original_ignored_owners)
        expect(output).to be_nil
      end
    end
  end
end
