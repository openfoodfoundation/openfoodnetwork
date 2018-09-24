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
          updated_ids: [0],
          enterprises_to_reset: [enterprise.id]
        }
      end

      before do
        allow(entry_processor)
          .to receive(:permission_by_id?).with(enterprise.id) { true }
      end

      context 'and not importing into inventory' do
        let(:variant) { create(:variant) }
        let(:enterprise) { variant.product.supplier }

        before do
          allow(entry_processor)
            .to receive(:importing_into_inventory?) { false }
        end

        it 'returns the number of products reset' do
          expect(reset_absent.call).to eq(2)
        end
      end

      context 'and importing into inventory' do
        let(:variant) { create(:variant) }
        let(:enterprise) { variant.product.supplier }
        let(:variant_override) do
          create(:variant_override, variant: variant, hub: enterprise)
        end

        before do
          variant_override

          allow(entry_processor)
            .to receive(:permission_by_id?).with(enterprise.id) { true }
        end

        before do
          allow(entry_processor)
            .to receive(:importing_into_inventory?) { true }
        end

        it 'returns nil' do
          expect(reset_absent.call).to be_nil
        end
      end
    end
  end

  describe '#products_reset_count' do
    let(:variant) { create(:variant) }
    let(:enterprise_id) { variant.product.supplier_id }

    before do
      allow(entry_processor)
        .to receive(:permission_by_id?).with(enterprise_id) { true }
    end

    let(:import_settings) do
      {
        settings: { 'reset_all_absent' => true },
        updated_ids: [0],
        enterprises_to_reset: [enterprise_id]
      }
    end

    it 'returns the number of reset products or variants' do
      reset_absent.call
      expect(reset_absent.products_reset_count).to eq(2)
    end
  end
end
