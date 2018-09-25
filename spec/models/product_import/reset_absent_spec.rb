require 'spec_helper'

describe ProductImport::ResetAbsent do
  let(:entry_processor) { instance_double(ProductImport::EntryProcessor) }

  let(:reset_absent) do
    described_class.new(entry_processor, settings, strategy)
  end

  describe '#call' do
    context 'when there are no enterprises_to_reset' do
      let(:settings) do
        instance_double(
          ProductImport::Settings,
          enterprises_to_reset: [],
          updated_ids: []
        )
      end

      let(:strategy) do
        instance_double(ProductImport::InventoryReset, supplier_ids: [])
      end

      it 'returns nil' do
        expect(reset_absent.call).to be_nil
      end
    end

    context 'when there are updated_ids and enterprises_to_reset' do
      let(:enterprise) { instance_double(Enterprise, id: 1) }

      let(:settings) do
        instance_double(
          ProductImport::Settings,
          updated_ids: [0],
          enterprises_to_reset: [enterprise.id.to_s]
        )
      end

      let(:strategy) { instance_double(ProductImport::ProductsReset) }

      before do
        allow(entry_processor)
          .to receive(:permission_by_id?).with(enterprise.id.to_s) { true }

        allow(strategy).to receive(:<<).with(enterprise.id)
        allow(strategy).to receive(:supplier_ids) { [enterprise.id] }
        allow(strategy).to receive(:reset).with([0], [enterprise.id]) { 2 }
      end

      it 'returns the number of products reset' do
        expect(reset_absent.call).to eq(2)
      end

      it 'resets the products of the specified suppliers' do
        expect(strategy).to receive(:reset).with([0], [enterprise.id]) { 2 }
        reset_absent.call
      end
    end

    context 'when the enterprise has no permission' do
      let(:enterprise) { instance_double(Enterprise, id: 1) }

      let(:settings) do
        instance_double(
          ProductImport::Settings,
          updated_ids: [0],
          enterprises_to_reset: [enterprise.id.to_s]
        )
      end

      let(:strategy) { instance_double(ProductImport::InventoryReset) }

      before do
        allow(entry_processor)
          .to receive(:permission_by_id?).with(enterprise.id.to_s) { false }

        allow(strategy).to receive(:supplier_ids) { [] }
      end

      it 'does not reset stock' do
        expect(strategy).not_to receive(:reset)
        reset_absent.call
      end
    end
  end

  describe '#products_reset_count' do
    let(:enterprise) { instance_double(Enterprise, id: 1) }

    let(:settings) do
      instance_double(
        ProductImport::Settings,
        updated_ids: [0],
        enterprises_to_reset: [enterprise.id.to_s]
      )
    end

    let(:strategy) { instance_double(ProductImport::InventoryReset) }

    before do
      allow(entry_processor)
        .to receive(:permission_by_id?).with(enterprise.id.to_s) { true }

      allow(strategy).to receive(:<<).with(enterprise.id)
      allow(strategy).to receive(:supplier_ids) { [enterprise.id] }
      allow(strategy).to receive(:reset).with([0], [enterprise.id]) { 1 }
    end

    it 'returns the number of reset variant overrides' do
      reset_absent.call
      expect(reset_absent.products_reset_count).to eq(1)
    end
  end
end
