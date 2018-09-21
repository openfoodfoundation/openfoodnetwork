require 'spec_helper'

describe ProductImport::ResetAbsent do
  let(:importer) { double(:importer) }
  let(:validator) { double(:validator) }
  let(:spreadsheet_data) { double(:spreadsheet_data) }
  let(:editable_enterprises) { double(:editable_enterprises) }
  let(:import_time) { double(:import_time) }
  let(:updated_ids) { double(:updated_ids) }

  let(:entry_processor) do
    ProductImport::EntryProcessor.new(
      importer,
      validator,
      import_settings,
      spreadsheet_data,
      editable_enterprises,
      import_time,
      updated_ids
    )
  end

  let(:reset_absent) { described_class.new(entry_processor) }

  describe '#call' do
    context 'when there are no settings' do
      let(:import_settings) { { updated_ids: [], enterprises_to_reset: [] } }

      it 'returns nil' do
        expect(reset_absent.call).to be_nil
      end
    end

    context 'when there are no updated_ids' do
      let(:import_settings) { { settings: [], enterprises_to_reset: [] } }

      it 'returns nil' do
        expect(reset_absent.call).to be_nil
      end
    end

    context 'when there are no enterprises_to_reset' do
      let(:import_settings) { { settings: [], updated_ids: [] } }

      it 'returns nil' do
        expect(reset_absent.call).to be_nil
      end
    end

    context 'when there are settings, updated_ids and enterprises_to_reset' do
      let(:import_settings) do
        {
          settings: { 'reset_all_absent' => true },
          updated_ids: [1],
          enterprises_to_reset: [2]
        }
      end

      before do
        allow(entry_processor).to receive(:permission_by_id?).with(2) { true }
      end

      context 'and not importing into inventory' do
        before do
          allow(entry_processor)
            .to receive(:importing_into_inventory?) { false }
        end

        it 'returns true' do
          expect(reset_absent.call).to eq(true)
        end
      end

      context 'and importing into inventory' do
        before do
          allow(entry_processor)
            .to receive(:importing_into_inventory?) { true }
        end

        it 'returns true' do
          expect(reset_absent.call).to eq(true)
        end
      end
    end
  end
end
