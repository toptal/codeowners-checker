# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Helpers::AddPatternIntoGroup do
  let(:add_pattern_into_group) { described_class.new(interactive_fix, pattern) }
  let(:interactive_fix) { Codeowners::Cli::InteractiveFix.new }

  include_context 'when owners prepared'
  include_context 'when new file pattern prepared'
  include_context 'when checker for cli prepared'

  describe '#run' do
    let(:suggesting_interactor) { add_pattern_into_group.__send__(:suggesting_interactor) }
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
      let(:main_group) { add_pattern_into_group.__send__(:main_group) }

      before do
        allow(suggesting_interactor).to receive(:success?).and_return(nil)
      end

      context 'when pattern was added into main_group' do
        let(:last_pattern_in_main_group) do
          main_group.__send__(:list).last
        end

        before do
          allow(add_pattern_into_group).to receive(:yes?).with(ask_message).and_return(true)
        end

        it 'returns from #run function without further actions' do
          add_pattern_into_group.run
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
