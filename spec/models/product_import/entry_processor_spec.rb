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
    let(:settings) { instance_double(ProductImport::Settings) }

    before do
      allow(ProductImport::ResetAbsent).to receive(:new) { reset_absent }
      allow(ProductImport::Settings).to receive(:new) { settings }
    end

    it 'delegates to ResetAbsent' do
      entry_processor.reset_absent_items

      expect(ProductImport::ResetAbsent)
        .to have_received(:new).with(entry_processor, settings)
    end
  end

  describe '#products_reset_count' do
    let(:reset_absent) { instance_double(ProductImport::ResetAbsent) }

    before do
      allow(ProductImport::ResetAbsent)
        .to receive(:new)
        .and_return(reset_absent)

      allow(reset_absent).to receive(:products_reset_count)
    end

    it 'delegates to ResetAbsent' do
      entry_processor.products_reset_count
      expect(reset_absent).to have_received(:products_reset_count)
    end
  end
end
