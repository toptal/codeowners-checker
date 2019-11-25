# frozen_string_literal: true

shared_context 'when subgroups for selected owner are exist' do
  let(:backend_team_api_heading) { '# Backend Team - API' }
  let(:backend_team_billing_heading) { '# Backend Team - Billing' }
  let(:codeowners_file_content) do
    [
      backend_team_api_heading,
      "pattern1 #{default_owner}",
      "pattern2 #{default_owner}",
      '',
      backend_team_billing_heading,
      "pattern3 #{default_owner}",
      "pattern4 #{default_owner}"
    ].map do |item|
      Codeowners::Checker::Group::Line.build(item)
    end
  end
  let(:main_group) do
    group = Codeowners::Checker::Group.new
    group.parse(codeowners_file_content)
    group
  end
  let(:subgroups) { main_group.subgroups_owned_by(pattern.owner) }

  before do
    allow(suggest_subgroup_for_pattern).to receive(:subgroups).and_return(subgroups)
    allow(suggest_subgroup_for_pattern).to receive(:ask).and_return(selected_group_index)
  end
end
