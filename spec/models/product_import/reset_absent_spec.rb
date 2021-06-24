# frozen_string_literal: true

require 'spec_helper'

module ProductImport
  describe ResetAbsent do
    let(:entry_processor) { instance_double(EntryProcessor) }

    let(:reset_absent) do
      described_class.new(entry_processor, settings, reset_stock_strategy)
    end

    describe '#call' do
      context 'when there are no enterprises_to_reset' do
        let(:settings) { instance_double(Settings, enterprises_to_reset: []) }
        let(:reset_stock_strategy) { instance_double(InventoryResetStrategy) }

        before do
          allow(reset_stock_strategy).to receive(:reset).with([]) { 0 }
        end

        it 'returns 0' do
          expect(reset_absent.call).to eq(0)
        end

        it 'calls the strategy' do
          reset_absent.call
          expect(reset_stock_strategy).to have_received(:reset)
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

        let(:reset_stock_strategy) {
          instance_double(Catalog::ProductImport::ProductsResetStrategy)
        }

        before do
          allow(entry_processor)
            .to receive(:permission_by_id?).with(enterprise.id.to_s) { true }

          allow(reset_stock_strategy)
            .to receive(:reset).with([enterprise.id]) { 2 }
        end

        it 'returns the number of products reset' do
          expect(reset_absent.call).to eq(2)
        end

        it 'resets the products of the specified suppliers' do
          reset_absent.call
          expect(reset_stock_strategy).to have_received(:reset)
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

          allow(reset_stock_strategy).to receive(:reset).with([nil]) { 0 }
        end

        it 'calls the strategy' do
          reset_absent.call
          expect(reset_stock_strategy).to have_received(:reset)
        end

        it 'returns 0' do
          expect(reset_absent.call).to eq(0)
        end
      end
    end
  end
end
