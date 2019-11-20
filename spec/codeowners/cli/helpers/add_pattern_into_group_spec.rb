# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Helpers::AddPatternIntoGroup do
  include_context 'when main cli handler setup'

  let(:add_pattern_into_group) do
    described_class.new(interactive_fix, pattern)
  end

  include_context 'when pattern related objects prepared'

  describe '#run' do
    let(:suggesting_interactor) do
      add_pattern_into_group.send(:suggesting_interactor)
    end

    let(:ask_message) { 'Add to the end of the CODEOWNERS file?' }

    context 'when one of suggested subgroups selected' do
      before do
        allow(suggesting_interactor).to receive(:success?).and_return(true)
      end

      it 'returns from #run function without further actions' do
        expect(add_pattern_into_group).not_to receive(:yes?)
        add_pattern_into_group.run
      end
    end

    context 'when nothing selected from suggested list' do
      let(:main_group) do
        add_pattern_into_group.send(:main_group)
      end

      before do
        allow(suggesting_interactor).to receive(:success?).and_return(nil)
      end

      context 'when pattern was added into main_group' do
        let(:last_pattern_in_main_group) do
          main_group.send(:list).last
        end

        before do
          allow(add_pattern_into_group).to receive(:yes?).with(ask_message).and_return(true)

          add_pattern_into_group.run
        end

        it 'returns from #run function without further actions' do
          expect(last_pattern_in_main_group.to_s).to eql(new_file_pattern_line)
        end
      end

      context 'when pattern was ignored' do
        before do
          allow(add_pattern_into_group).to receive(:yes?).with(ask_message).and_return(false)
        end

        it 'returns from #run function without further actions' do
          expect(main_group).not_to receive(:add)
          add_pattern_into_group.run
        end
      end
    end
  end
end
