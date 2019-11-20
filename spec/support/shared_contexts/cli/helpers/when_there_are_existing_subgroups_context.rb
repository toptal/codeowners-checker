# frozen_string_literal: true

require 'spec_helper'

shared_context 'when there are subgroups which are belong to selected owner' do
  let(:existing_subgroups_of_selected_owner_group) do
    [
      foo_subgroup,
      bar_subgroup
    ]
  end

  let(:foo_subgroup_heading) { '# TopNinjas - WEB Area' }
  let(:foo_pattern_one) { "foo_one.rb #{default_owner}" }
  let(:foo_pattern_two) { "foo_two.rb #{default_owner}" }
  let(:foo_subgroup_list) do
    [
      Codeowners::Checker::Group::Comment.new(foo_subgroup_heading),
      Codeowners::Checker::Group::Pattern.new(foo_pattern_one),
      Codeowners::Checker::Group::Pattern.new(foo_pattern_two)
    ]
  end
  let(:foo_subgroup) do
    inst = Codeowners::Checker::Group.new
    inst.instance_variable_set(:@list, foo_subgroup_list)

    inst
  end

  let(:bar_subgroup_heading) { '# TopNinjas - API Area' }
  let(:bar_pattern_one) { "bar_one.rb #{default_owner}" }
  let(:bar_pattern_two) { "bar_two.rb #{default_owner}" }
  let(:bar_subgroup_list) do
    [
      Codeowners::Checker::Group::Comment.new(bar_subgroup_heading),
      Codeowners::Checker::Group::Pattern.new(bar_pattern_one),
      Codeowners::Checker::Group::Pattern.new(bar_pattern_two)
    ]
  end
  let(:bar_subgroup) do
    inst = Codeowners::Checker::Group.new
    inst.instance_variable_set(:@list, bar_subgroup_list)

    inst
  end

  before do
    allow(suggest_subgroup_for_pattern.send(:main_group)).to receive(:subgroups_owned_by).and_return(
      existing_subgroups_of_selected_owner_group
    )
    allow(suggest_subgroup_for_pattern).to receive(:ask).and_return(selected_group_index)
  end
end
