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
          importing_into_inventory?: true
        )
      end

      it 'delegates to ResetAbsent' do
        entry_processor.reset_absent_items

        expect(ProductImport::ResetAbsent)
          .to have_received(:new)
          .with(entry_processor, settings, ProductImport::InventoryReset)
      end
    end
  end

  describe '#products_reset_count' do
    let(:reset_absent) { instance_double(ProductImport::ResetAbsent) }

    before do
      allow(ProductImport::ResetAbsent)
        .to receive(:new)
        .and_return(reset_absent)

      allow(reset_absent).to receive(:products_reset_count)

      allow(import_settings).to receive(:[]).with(:settings)
    end

    it 'delegates to ResetAbsent' do
      entry_processor.products_reset_count
      expect(reset_absent).to have_received(:products_reset_count)
    end
  end

  describe '#importing_into_inventory?' do
    let(:settings) do
      instance_double(ProductImport::Settings, importing_into_inventory?: true)
    end

    before do
      allow(ProductImport::Settings).to receive(:new) { settings }
    end

    it 'delegates to Settings' do
      entry_processor.importing_into_inventory?
      expect(settings).to have_received(:importing_into_inventory?)
    end
  end
end
