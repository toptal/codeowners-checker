# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Helpers::SuggestSubgroupForPattern do
  include_context 'when main cli handler setup'

  let(:suggest_subgroup_for_pattern) do
    described_class.new(interactive_fix, pattern)
  end

  include_context 'when pattern related objects prepared'

  describe '#run' do
    context 'when there are existing subgroups for selected owner' do
      include_context 'when there are subgroups which are belong to selected owner'

      let(:selected_subgroup_valid_trigger) do
        suggest_subgroup_for_pattern.send(:selected_subgroup_index_is_valid?)
      end
      let(:selected_subgroup) do
        suggest_subgroup_for_pattern.send(:subgroups)[selected_group_index - 1]
      end
      let(:last_pattern_in_selected_subgroup) do
        selected_subgroup.send(:list).last
      end

      before do
        suggest_subgroup_for_pattern.run
      end

      context 'when subgroup selected from suggested list' do
        let(:selected_group_index) do
          existing_subgroups_of_selected_owner_group.size
        end

        it 'adds new pattern into selected subgroup' do
          expect(selected_subgroup_valid_trigger).to be_truthy
          expect(suggest_subgroup_for_pattern).to be_success
          expect(last_pattern_in_selected_subgroup.to_s).to eq(new_file_pattern_line)
        end
      end

      context 'when provided subgroup index is wrong' do
        let(:selected_group_index) do
          existing_subgroups_of_selected_owner_group.size + 1 # not real
        end

        it 'returns from #run function without further actions' do
          expect(selected_subgroup_valid_trigger).to be_falsey
          expect(suggest_subgroup_for_pattern).not_to be_success
        end
      end
    end

    context 'when there are no existing subgroups for selected owner' do
      it 'returns from #run function without further actions' do
        expect(suggest_subgroup_for_pattern).not_to receive(:show_suggestion_dialog)
        suggest_subgroup_for_pattern.run

        expect(suggest_subgroup_for_pattern).not_to be_success
      end
    end
  end

  describe '#show_suggestion_dialog' do
    include_context 'when there are subgroups which are belong to selected owner'

    let(:selected_group_index) { 2 }
    let(:dialog_output) do
      suggest_subgroup_for_pattern.send(:show_suggestion_dialog)
    end

    it 'displays list of existing subgroups for selected owner' do
      expect { dialog_output }.to output(<<~MESSAGE).to_stdout
        Possible groups to which the pattern belongs:
        1 - #{foo_subgroup_heading}
        2 - #{bar_subgroup_heading}
      MESSAGE
    end
  end
end
