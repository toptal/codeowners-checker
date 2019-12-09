# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Wizards::NewFileWizard do
  let(:wizard) { described_class.new('@default') }
  let(:codeowners_main_group) { instance_double(Codeowners::Checker::Group) }

  before do
    allow(codeowners_main_group).to receive(:owners).and_return(['@jeff', '@annie'])

    allow(wizard).to receive(:ask)
    allow(wizard).to receive(:puts)
    allow(wizard).to receive(:yes?)
  end

  describe '#suggest_adding' do
    let(:file) { 'new/file.rb' }
    let(:prompt) { <<~QUESTION }
      File added: "new/file.rb". Add owner to the CODEOWNERS file?
      (y) yes
      (i) ignore
      (q) quit and save
    QUESTION
    let(:prompt_options) { %w[y i q] }

    it 'suggests file addition' do
      wizard.suggest_adding(file, codeowners_main_group)

      expect(wizard).to have_received(:ask).with(prompt, limited_to: prompt_options)
    end

    context 'when the user chose to add' do
      let(:user_input_owner) { '' }
      let(:user_input_another_owner) { '' }

      before do
        allow(wizard).to receive(:ask).and_return('y', user_input_owner, user_input_another_owner)
      end

      it 'prompts owner listing exising owners sorted' do
        wizard.suggest_adding(file, codeowners_main_group)

        expect(wizard).to have_received(:ask).with(prompt, limited_to: prompt_options).ordered
        expect(wizard).to have_received(:puts).with('Owners:').ordered
        expect(wizard).to have_received(:puts).with('1 - @annie').ordered
        expect(wizard).to have_received(:puts).with('2 - @jeff').ordered
        expect(wizard).to have_received(:puts).with('Choose owner, add new one or leave empty to use "@default".').ordered # rubocop:disable Metrics/LineLength
        expect(wizard).to have_received(:ask).with('New owner: ').once.ordered
      end

      context 'when the user chose to use exising owner' do
        let(:user_input_owner) { '2' }

        it 'returns [:add, pattern_with_chosen_owner]' do
          choice, pattern = wizard.suggest_adding(file, codeowners_main_group)

          expect(choice).to be(:add)
          expect(pattern).to eq(Codeowners::Checker::Group::Pattern.new('new/file.rb @jeff'))
        end
      end

      context 'when the user chose to use default owner' do
        let(:user_input_owner) { '' }

        it 'returns [:add, pattern_with_default_owner]' do
          choice, pattern = wizard.suggest_adding(file, codeowners_main_group)

          expect(choice).to be(:add)
          expect(pattern).to eq(Codeowners::Checker::Group::Pattern.new('new/file.rb @default'))
        end
      end

      context 'when the user chose to use new owner' do
        let(:user_input_owner) { '@new' }

        it 'returns [:add, pattern_with_new_owner]' do
          choice, pattern = wizard.suggest_adding(file, codeowners_main_group)

          expect(choice).to be(:add)
          expect(pattern).to eq(Codeowners::Checker::Group::Pattern.new('new/file.rb @new'))
        end
      end

      context 'when the user inputs invalid owner' do
        let(:user_input_owner) { '0' }

        it 'prompts again' do
          wizard.suggest_adding(file, codeowners_main_group)

          expect(wizard).to have_received(:ask).with('New owner: ').twice.ordered
        end
      end

      context 'when the user inputs valid owner after invalid one' do
        let(:user_input_owner) { 'invalid_owner' }
        let(:user_input_another_owner) { '@valid' }

        it 'returns [:add, pattern_with_valid_owner]' do
          choice, pattern = wizard.suggest_adding(file, codeowners_main_group)

          expect(choice).to be(:add)
          expect(pattern).to eq(Codeowners::Checker::Group::Pattern.new('new/file.rb @valid'))
        end
      end
    end

    context 'when the user chose to ignore' do
      before do
        allow(wizard).to receive(:ask).and_return('i')
      end

      it 'returns :ignore' do
        choice = wizard.suggest_adding(file, codeowners_main_group)

        expect(choice).to be(:ignore)
      end
    end

    context 'when the user chose to quit' do
      before do
        allow(wizard).to receive(:ask).and_return('q')
      end

      it 'returns :quit' do
        choice = wizard.suggest_adding(file, codeowners_main_group)

        expect(choice).to be(:quit)
      end
    end
  end

  describe '#select_operation' do
    let(:pattern) { instance_double(Codeowners::Checker::Group::Pattern) }
    let(:subgroup1) { instance_double(Codeowners::Checker::Group) }
    let(:subgroup2) { instance_double(Codeowners::Checker::Group) }

    before do
      allow(subgroup1).to receive(:title).and_return('rangers')
      allow(subgroup2).to receive(:title).and_return('druids')
      allow(codeowners_main_group).to receive(:subgroups_owned_by) do |owner|
        owner == '@the_owner' ? [subgroup1, subgroup2] : []
      end
      allow(pattern).to receive(:owner).and_return(owner)
    end

    shared_examples 'suggesting to add to main group' do
      it 'prompts to add to main group' do
        wizard.select_operation(pattern, codeowners_main_group)

        expect(wizard).to have_received(:yes?).with('Add to the end of the CODEOWNERS file?')
      end

      context 'when the user agreed to add to main group' do
        before do
          allow(wizard).to receive(:yes?).and_return(true)
        end

        it 'returns :add_to_main_group' do
          choice = wizard.select_operation(pattern, codeowners_main_group)

          expect(choice).to be(:add_to_main_group)
        end
      end

      context 'when the user declied to add to main group' do
        before do
          allow(wizard).to receive(:yes?).and_return(false)
        end

        it 'returns :ignore' do
          choice = wizard.select_operation(pattern, codeowners_main_group)

          expect(choice).to be(:ignore)
        end
      end
    end

    context 'when there is no subgroups available' do
      let(:owner) { '@some_owner' }

      it_behaves_like 'suggesting to add to main group'
    end

    context 'when there are subgroups' do
      let(:owner) { '@the_owner' }

      it 'prompts listing subgroups as is' do
        wizard.select_operation(pattern, codeowners_main_group)

        expect(wizard).to have_received(:puts).with('Possible groups to which the pattern belongs: ').ordered
        expect(wizard).to have_received(:puts).with('1 - rangers').ordered
        expect(wizard).to have_received(:puts).with('2 - druids').ordered
        expect(wizard).to have_received(:ask).with('Choose group: ').ordered
      end

      context 'when the user chose subgroup' do
        before do
          allow(wizard).to receive(:ask).and_return('2')
        end

        it 'returns [:insert_into_subgroup, chosen_subgroup]' do
          choice, subgroup = wizard.select_operation(pattern, codeowners_main_group)

          expect(choice).to be(:insert_into_subgroup)
          expect(subgroup).to be(subgroup2)
        end
      end

      context 'when the user input is invalid' do
        before do
          allow(wizard).to receive(:ask).and_return('')
        end

        it_behaves_like 'suggesting to add to main group'
      end
    end
  end
end
