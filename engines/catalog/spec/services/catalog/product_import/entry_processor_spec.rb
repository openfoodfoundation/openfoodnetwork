# frozen_string_literal: true

require 'spec_helper'

describe ProductImport::EntryProcessor do
  let(:importer) { double(:importer) }
  let(:validator) { double(:validator) }
  let(:import_settings) { double(:import_settings) }
  let(:spreadsheet_data) { double(:spreadsheet_data) }
  let(:editable_enterprises) { double(:editable_enterprises) }
  let(:import_time) { double(:import_time) }
  let(:updated_ids) { double(:updated_ids) }

  let(:entry_processor) do
    described_class.new(
      importer,
      validator,
      import_settings,
      spreadsheet_data,
      editable_enterprises,
      import_time,
      updated_ids
    )
  end

  describe '#reset_absent_items' do
    let(:reset_absent) do
      instance_double(ProductImport::ResetAbsent, call: true)
    end

    before do
      allow(ProductImport::ResetAbsent).to receive(:new) { reset_absent }
      allow(ProductImport::Settings).to receive(:new) { settings }
    end

    context 'when there is no data' do
      let(:settings) do
        instance_double(
          ProductImport::Settings,
          data_for_stock_reset?: false,
          reset_all_absent?: true
        )
      end

      it 'does not call ResetAbsent' do
        entry_processor.reset_absent_items
        expect(reset_absent).not_to have_received(:call)
      end
    end

    context 'when reset_all_absent is not set' do
      let(:settings) do
        instance_double(
          ProductImport::Settings,
          data_for_stock_reset?: true,
          reset_all_absent?: false
        )
      end

      it 'does not call ResetAbsent' do
        entry_processor.reset_absent_items
        expect(reset_absent).not_to have_received(:call)
      end
    end

    context 'when there is data and reset_all_absent is set' do
      let(:settings) do
        instance_double(
          ProductImport::Settings,
          data_for_stock_reset?: true,
          reset_all_absent?: true,
          updated_ids: [1]
        )
      end

      context 'when importing into inventory' do
        let(:reset_stock_strategy) do
          instance_double(ProductImport::InventoryResetStrategy)
        end

        before do
          allow(settings).to receive(:importing_into_inventory?) { true }

          allow(ProductImport::InventoryResetStrategy)
            .to receive(:new).with([1]) { reset_stock_strategy }
        end

        it 'delegates to ResetAbsent passing the appropriate reset_stock_strategy' do
          entry_processor.reset_absent_items

          expect(ProductImport::ResetAbsent)
            .to have_received(:new)
            .with(entry_processor, settings, reset_stock_strategy)
        end
      end

      context 'when not importing into inventory' do
        let(:reset_stock_strategy) do
          instance_double(Catalog::ProductImport::ProductsResetStrategy)
        end

        before do
          allow(settings).to receive(:importing_into_inventory?) { false }

          allow(Catalog::ProductImport::ProductsResetStrategy)
            .to receive(:new).with([1]) { reset_stock_strategy }
        end

        it 'delegates to ResetAbsent passing the appropriate reset_stock_strategy' do
          entry_processor.reset_absent_items

          expect(ProductImport::ResetAbsent)
            .to have_received(:new)
            .with(entry_processor, settings, reset_stock_strategy)
        end
      end
    end
  end

  describe '#products_reset_count' do
    let(:settings) do
      instance_double(
        ProductImport::Settings,
        data_for_stock_reset?: true,
        reset_all_absent?: true,
        importing_into_inventory?: false,
        updated_ids: [1]
      )
    end

    context 'when reset_absent_items was executed' do
      let(:reset_absent) do
        instance_double(ProductImport::ResetAbsent, call: 2)
      end

      before do
        allow(ProductImport::Settings).to receive(:new) { settings }
        allow(ProductImport::ResetAbsent).to receive(:new) { reset_absent }
      end

      it 'returns the number of items affected by the last reset' do
        entry_processor.reset_absent_items
        expect(entry_processor.products_reset_count).to eq(2)
      end
    end

    context 'when ResetAbsent was not called' do
      it 'returns 0' do
        expect(entry_processor.products_reset_count).to eq(0)
      end
    end
  end
end
