# frozen_string_literal: true

RSpec.describe Codeowners::Cli::InteractiveResolver do
  let(:resolver) { described_class.new(checker, validate_owners, '@default_owner') }
  let(:validate_owners) { false }
  let(:checker) { instance_double(Codeowners::Checker) }
  let(:owners_list) { instance_double(Codeowners::Checker::OwnersList) }
  let(:main_codeowners_group) { instance_double(Codeowners::Checker::Group) }
  let(:new_file_wizard) { instance_double(Codeowners::Cli::Wizards::NewFileWizard) }
  let(:new_owner_wizard) { instance_double(Codeowners::Cli::Wizards::NewOwnerWizard) }
  let(:unrecognized_line_wizard) { instance_double(Codeowners::Cli::Wizards::UnrecognizedLineWizard) }
  let(:useless_pattern_wizard) { instance_double(Codeowners::Cli::Wizards::UselessPatternWizard) }

  before do
    allow(Codeowners::Cli::Wizards::NewFileWizard).to receive(:new).and_return(new_file_wizard)
    allow(Codeowners::Cli::Wizards::NewOwnerWizard).to receive(:new).and_return(new_owner_wizard)
    allow(Codeowners::Cli::Wizards::UnrecognizedLineWizard).to receive(:new).and_return(unrecognized_line_wizard)
    allow(Codeowners::Cli::Wizards::UselessPatternWizard).to receive(:new).and_return(useless_pattern_wizard)
    allow(checker).to receive(:owners_list).and_return(owners_list)
    allow(checker).to receive(:main_group).and_return(main_codeowners_group)
  end

  describe '#print_epilogue' do
    context 'when just created' do
      it 'prints no epilogue' do
        expect { resolver.print_epilogue }.not_to output.to_stdout
      end
    end

    context 'when ignored some owners' do
      before do
        allow(new_owner_wizard).to receive(:suggest_adding).and_return(:ignore)
        resolver.handle_new_owner(Codeowners::Checker::Group::Pattern.new('pattern1 @ownerA'), '@ownerA')
        resolver.handle_new_owner(Codeowners::Checker::Group::Pattern.new('pattern2 @ownerB'), '@ownerB')
      end

      it 'outputs ignored owners list' do
        expect { resolver.print_epilogue }.to output(<<~OUTPUT).to_stdout
          Ignored owners:
           * @ownerA
           * @ownerB
        OUTPUT
      end
    end
  end

  describe '#handle_new_file' do
    let(:file) { 'some/file.rb' }
    let(:owner) { '@owner' }
    let(:pattern) { Codeowners::Checker::Group::Pattern.new('some/file.rb @owner') }
    let(:user_addition_choice) { nil }
    let(:user_operation_choice) { nil }

    before do
      allow(new_file_wizard).to receive(:suggest_adding).and_return(user_addition_choice)
      allow(new_file_wizard).to receive(:select_operation).and_return(user_operation_choice)
    end

    it 'suggests to add ot' do
      resolver.handle_new_file(file)

      expect(new_file_wizard).to have_received(:suggest_adding).with(file, main_codeowners_group)
    end

    context 'when the user chose to quit' do
      let(:user_addition_choice) { :quit }

      it 'throws :user_quit' do
        expect { resolver.handle_new_file(file) }.to throw_symbol(:user_quit)
      end
    end

    context 'when the user chose to ignore' do
      let(:user_addition_choice) { :ignore }

      it 'does nothing' do
        expect { resolver.handle_new_file(file) }.not_to change(resolver, :made_changes?)
      end
    end

    context 'when the user chose to add' do
      let(:user_addition_choice) { [:add, pattern] }

      before do
        allow(resolver).to receive(:handle_new_owner).with(pattern, owner)
      end

      context 'when validate_owners is on' do
        let(:validate_owners) { true }

        it 'handles invalid owner like new one' do
          allow(owners_list).to receive(:valid_owner?).with(owner).and_return(false)

          resolver.handle_new_file(file)

          expect(owners_list).to have_received(:valid_owner?).with(owner)
          expect(resolver).to have_received(:handle_new_owner).with(pattern, owner)
        end

        it 'does not handles valid owners like new one' do
          allow(owners_list).to receive(:valid_owner?).with(owner).and_return(true)

          resolver.handle_new_file(file)

          expect(owners_list).to have_received(:valid_owner?).with(owner)
          expect(resolver).not_to have_received(:handle_new_owner)
        end
      end

      context 'when validate_owners is off' do
        let(:validate_owners) { false }

        it 'does not validates owner' do
          allow(owners_list).to receive(:valid_owner?)

          resolver.handle_new_file(file)

          expect(owners_list).not_to have_received(:valid_owner?)
        end
      end

      context 'when the user chose to insert into subgroup' do
        let(:subgroup) { instance_double(Codeowners::Checker::Group) }
        let(:user_operation_choice) { [:insert_into_subgroup, subgroup] }

        before do
          allow(subgroup).to receive(:insert).with(pattern)
        end

        it 'inserts into subgroup and marks changes' do
          expect { resolver.handle_new_file(file) }.to change(resolver, :made_changes?).to(true)
          expect(subgroup).to have_received(:insert).with(pattern)
        end
      end

      context 'when the user chose to add to main group' do
        let(:user_operation_choice) { :add_to_main_group }

        before do
          allow(main_codeowners_group).to receive(:add).with(pattern)
        end

        it 'adds to main group and marks changes' do
          expect { resolver.handle_new_file(file) }.to change(resolver, :made_changes?).to(true)
          expect(main_codeowners_group).to have_received(:add).with(pattern)
        end
      end

      context 'when the user chose to ignore' do
        let(:user_operation_choice) { :ignore }

        it 'does nothing' do
          expect { resolver.handle_new_file(file) }.not_to change(resolver, :made_changes?)
        end
      end
    end
  end

  describe '#handle_new_owner' do
    let(:file) { 'some/file.rb' }
    let(:owner) { '@owner' }
    let(:pattern) { Codeowners::Checker::Group::Pattern.new('some/file.rb @owner') }
    let(:another_pattern) { Codeowners::Checker::Group::Pattern.new('another/file.rb @owner') }
    let(:user_choice) { nil }

    before do
      allow(new_owner_wizard).to receive(:suggest_adding).and_return(user_choice)
    end

    it 'suggests to add it' do
      resolver.handle_new_owner(pattern, owner)

      expect(new_owner_wizard).to have_received(:suggest_adding).with(pattern, owner)
    end

    context 'when the user chose to add' do
      let(:user_choice) { :add }

      before do
        allow(owners_list).to receive(:<<)
      end

      it 'adds it to owners list and marks changes' do
        expect { resolver.handle_new_owner(pattern, owner) }.to change(resolver, :made_changes?).to(true)
        expect(owners_list).to have_received(:<<).with(owner)
      end
    end

    context 'when the user chose to ignore' do
      let(:user_choice) { :ignore }

      it 'does nothing on next call and includes it to epilogue' do
        resolver.handle_new_owner(pattern, owner)
        resolver.handle_new_owner(another_pattern, owner)

        expect(new_owner_wizard).to have_received(:suggest_adding).once
        expect { resolver.print_epilogue }.to output(<<~OUTPUT).to_stdout
          Ignored owners:
           * @owner
        OUTPUT
      end
    end

    context 'when the user chose to quit' do
      let(:user_choice) { :quit }

      it 'throws :user_quit' do
        expect { resolver.handle_new_owner(pattern, owner) }.to throw_symbol(:user_quit)
      end
    end
  end

  describe '#handle_useless_pattern' do
    let(:file) { 'useless/pattern/*.rb' }
    let(:owner) { '@owner' }
    let(:pattern) { Codeowners::Checker::Group::Pattern.new('useless/pattern/*.rb @owner') }
    let(:new_pattern) { 'new/pattern/*.rb' }
    let(:user_choice) { nil }

    before do
      allow(useless_pattern_wizard).to receive(:suggest_fixing).and_return(user_choice)
    end

    it 'suggests fixing it' do
      resolver.handle_useless_pattern(pattern)

      expect(useless_pattern_wizard).to have_received(:suggest_fixing).with(pattern)
    end

    context 'when the user chose to replace it' do
      let(:user_choice) { [:replace, new_pattern] }

      before do
        allow(pattern).to receive(:pattern=)
      end

      it 'replaces line\'s pattern and marks changes' do
        expect { resolver.handle_useless_pattern(pattern) }.to change(resolver, :made_changes?).to(true)
        expect(pattern).to have_received(:pattern=).with(new_pattern)
      end
    end

    context 'when the user chose to ignore it' do
      let(:user_choice) { :ignore }

      it 'does nothing' do
        expect { resolver.handle_useless_pattern(pattern) }.not_to change(resolver, :made_changes?)
      end
    end

    context 'when the user chose to delete it' do
      let(:user_choice) { :delete }

      before do
        allow(pattern).to receive(:remove!)
      end

      it 'deletes line and marks changes' do
        expect { resolver.handle_useless_pattern(pattern) }.to change(resolver, :made_changes?).to(true)
        expect(pattern).to have_received(:remove!)
      end
    end

    context 'when the user chose to quit' do
      let(:user_choice) { :quit }

      it 'throws :user_quit' do
        expect { resolver.handle_useless_pattern(pattern) }.to throw_symbol(:user_quit)
      end
    end
  end

  describe '#process_parsed_line' do
    let(:normal_line) { Codeowners::Checker::Group::Pattern.new('some/file.rb @owner') }
    let(:unrecognized_line) { Codeowners::Checker::Group::UnrecognizedLine.new('some unrecognized line') }
    let(:user_choice) { nil }

    before do
      allow(unrecognized_line_wizard).to receive(:suggest_fixing).and_return(user_choice)
    end

    context 'when line is normal' do
      let(:line) { Codeowners::Checker::Group::Pattern.new('some/file.rb @owner') }

      it 'returns it back' do
        output = resolver.process_parsed_line(normal_line)

        expect(output).to be(normal_line)
      end

      it 'marks not changes' do
        expect { resolver.process_parsed_line(normal_line) }.not_to change(resolver, :made_changes?)
      end
    end

    context 'when line is unrecognized' do
      let(:new_string) { 'some/file.rb @owner' }
      let(:new_line) { Codeowners::Checker::Group::Pattern.new('some/file.rb @owner') }

      it 'suggests fixing it' do
        resolver.process_parsed_line(unrecognized_line)

        expect(unrecognized_line_wizard).to have_received(:suggest_fixing).with(unrecognized_line)
      end

      context 'when the user chose to replace it' do
        let(:user_choice) { [:replace, new_line] }

        it 'returns new line' do
          output = resolver.process_parsed_line(unrecognized_line)
          expect(output).to be(new_line)
        end

        it 'marks changes' do
          expect { resolver.process_parsed_line(unrecognized_line) }.to change(resolver, :made_changes?).to(true)
        end
      end

      context 'when the user chose to ignore it' do
        let(:user_choice) { :ignore }

        it 'returns same line' do
          output = resolver.process_parsed_line(unrecognized_line)
          expect(output).to be(unrecognized_line)
        end

        it 'marks no changes' do
          expect { resolver.process_parsed_line(unrecognized_line) }.not_to change(resolver, :made_changes?)
        end
      end

      context 'when the user chose to delete it' do
        let(:user_choice) { :delete }

        it 'returns nil' do
          output = resolver.process_parsed_line(unrecognized_line)
          expect(output).to be_nil
        end

        it 'marks changes' do
          expect { resolver.process_parsed_line(unrecognized_line) }.to change(resolver, :made_changes?).to(true)
        end
      end
    end
  end
end
