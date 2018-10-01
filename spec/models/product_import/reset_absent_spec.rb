require 'spec_helper'

module ProductImport
  describe ResetAbsent do
    let(:entry_processor) { instance_double(EntryProcessor) }

    let(:reset_absent) do
      described_class.new(entry_processor, settings, reset_stock_strategy)
    end

    describe '#call' do
      context 'when there are no enterprises_to_reset' do
        let(:settings) do
          instance_double(
            Settings,
            enterprises_to_reset: []
          )
        end

        let(:reset_stock_strategy) do
          instance_double(InventoryResetStrategy, supplier_ids: [])
        end

        it 'returns nil' do
          expect(reset_absent.call).to be_nil
        end
      end

      context 'when there are enterprises_to_reset' do
        let(:enterprise) { instance_double(Enterprise, id: 1) }

        let(:settings) do
          instance_double(
            Settings,
            enterprises_to_reset: [enterprise.id.to_s]
          )
        end

        let(:reset_stock_strategy) { instance_double(ProductsResetStrategy) }

        before do
          allow(entry_processor)
            .to receive(:permission_by_id?).with(enterprise.id.to_s) { true }

          allow(reset_stock_strategy).to receive(:<<).with(enterprise.id)
          allow(reset_stock_strategy)
            .to receive(:supplier_ids) { [enterprise.id] }
          allow(reset_stock_strategy).to receive(:reset) { 2 }
        end

        it 'returns the number of products reset' do
          expect(reset_absent.call).to eq(2)
        end

        it 'resets the products of the specified suppliers' do
          expect(reset_stock_strategy).to receive(:reset) { 2 }
          reset_absent.call
        end
      end

      context 'when the enterprise has no permission' do
        let(:enterprise) { instance_double(Enterprise, id: 1) }

        let(:settings) do
          instance_double(
            Settings,
            enterprises_to_reset: [enterprise.id.to_s]
          )
        end

        let(:reset_stock_strategy) { instance_double(InventoryResetStrategy) }

        before do
          allow(entry_processor)
            .to receive(:permission_by_id?).with(enterprise.id.to_s) { false }

          allow(reset_stock_strategy).to receive(:supplier_ids) { [] }
        end

        it 'does not reset stock' do
          expect(reset_stock_strategy).not_to receive(:reset)
          reset_absent.call
        end
      end
    end

    describe '#products_reset_count' do
      let(:enterprise) { instance_double(Enterprise, id: 1) }

      let(:settings) do
        instance_double(
          Settings,
          enterprises_to_reset: [enterprise.id.to_s]
        )
      end

      let(:reset_stock_strategy) { instance_double(InventoryResetStrategy) }

      before do
        allow(entry_processor)
          .to receive(:permission_by_id?).with(enterprise.id.to_s) { true }

        allow(reset_stock_strategy).to receive(:<<).with(enterprise.id)
        allow(reset_stock_strategy)
          .to receive(:supplier_ids) { [enterprise.id] }
        allow(reset_stock_strategy).to receive(:reset) { 1 }
      end

      it 'returns the number of reset variant overrides' do
        reset_absent.call
        expect(reset_absent.products_reset_count).to eq(1)
      end
    end
  end
end
