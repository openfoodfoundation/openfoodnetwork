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
    let(:reset_absent) { double(ProductImport::ResetAbsent, call: true) }

    before do
      allow(ProductImport::ResetAbsent)
        .to receive(:new)
        .and_return(reset_absent)
    end

    it 'delegates to ResetAbsent' do
      entry_processor.reset_absent_items

      expect(ProductImport::ResetAbsent)
        .to have_received(:new).with(entry_processor)
    end
  end
end
