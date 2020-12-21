# frozen_string_literal: true

require 'spec_helper'

describe ProductImport::Settings do
  let(:settings) { described_class.new(import_settings) }

  describe '#defaults' do
    let(:entry) { instance_double(ProductImport::SpreadsheetEntry) }
    let(:import_settings) { {} }

    context 'when there are no settings' do
      it 'returns false' do
        expect(settings.defaults(entry)).to be_falsey
      end
    end

    context 'when there are settings' do
      let(:entry) do
        instance_double(ProductImport::SpreadsheetEntry, enterprise_id: 1)
      end
      let(:import_settings) { { settings: {} } }

      context 'and there is no data for the specified entry' do
        it 'returns a falsey' do
          expect(settings.defaults(entry)).to be_falsey
        end
      end

      context 'and there is data for the specified entry' do
        context 'and it has no defaults' do
          let(:import_settings) do
            { settings: { '1' => { 'foo' => 'bar' } } }
          end

          it 'returns a falsey' do
            expect(settings.defaults(entry)).to be_falsey
          end
        end

        context 'and it has defaults' do
          let(:import_settings) do
            { settings: { '1' => { 'defaults' => 'default value' } } }
          end

          it 'returns a truthy' do
            expect(settings.defaults(entry)).to eq('default value')
          end
        end
      end
    end
  end

  describe '#settings' do
    context 'when settings are specified' do
      let(:import_settings) { { settings: { foo: 'bar' } } }

      it 'returns them' do
        expect(settings.settings).to eq(foo: 'bar')
      end
    end

    context 'when settings are not specified' do
      let(:import_settings) { {} }

      it 'returns nil' do
        expect(settings.settings).to be_nil
      end
    end
  end

  describe '#updated_ids' do
    context 'when updated_ids are specified' do
      let(:import_settings) { { updated_ids: [2] } }

      it 'returns them' do
        expect(settings.updated_ids).to eq([2])
      end
    end

    context 'when updated_ids are not specified' do
      let(:import_settings) { {} }

      it 'returns nil' do
        expect(settings.updated_ids).to be_nil
      end
    end
  end

  describe '#enterprises_to_reset' do
    context 'when enterprises_to_reset are specified' do
      let(:import_settings) { { enterprises_to_reset: [2] } }

      it 'returns them' do
        expect(settings.enterprises_to_reset).to eq([2])
      end
    end

    context 'when enterprises_to_reset are not specified' do
      let(:import_settings) { {} }

      it 'returns nil' do
        expect(settings.enterprises_to_reset).to be_nil
      end
    end
  end

  describe '#importing_into_inventory?' do
    context 'when :settings is specified' do
      context 'and import_into is not specified' do
        let(:import_settings) { { settings: {} } }

        it 'returns false' do
          expect(settings.importing_into_inventory?).to eq(false)
        end
      end

      context 'and import_into is equal to inventories' do
        let(:import_settings) do
          { settings: { 'import_into' => 'inventories' } }
        end

        it 'returns true' do
          expect(settings.importing_into_inventory?).to eq(true)
        end
      end

      context 'and import_into is not equal to inventories' do
        let(:import_settings) do
          { settings: { 'import_into' => 'other' } }
        end

        it 'returns false' do
          expect(settings.importing_into_inventory?).to eq(false)
        end
      end
    end

    context 'when :settings is not specified' do
      let(:import_settings) { {} }

      it 'returns falsy' do
        expect(settings.importing_into_inventory?).to be_falsy
      end
    end
  end

  describe '#reset_all_absent?' do
    context 'when :settings is not specified' do
      let(:import_settings) { {} }

      it 'raises' do
        expect { settings.reset_all_absent? }.to raise_error(NoMethodError)
      end
    end

    context 'when reset_all_absent is not set' do
      let(:import_settings) do
        { settings: {} }
      end

      it 'returns nil' do
        expect(settings.reset_all_absent?).to be_nil
      end
    end

    context 'when reset_all_absent is set' do
      let(:import_settings) do
        { settings: { 'reset_all_absent' => true } }
      end

      it 'returns true' do
        expect(settings.reset_all_absent?).to eq(true)
      end
    end
  end

  describe '#data_for_stock_reset?' do
    context 'when there are no settings' do
      let(:import_settings) do
        {
          updated_ids: [],
          enterprises_to_reset: []
        }
      end

      it 'returns false' do
        expect(settings.data_for_stock_reset?).to eq(false)
      end
    end

    context 'when there are no updated_ids' do
      let(:import_settings) do
        {
          settings: [],
          enterprises_to_reset: []
        }
      end

      it 'returns false' do
        expect(settings.data_for_stock_reset?).to eq(false)
      end
    end

    context 'when there are no enterprises_to_reset' do
      let(:import_settings) do
        {
          settings: [],
          updated_ids: []
        }
      end

      it 'returns false' do
        expect(settings.data_for_stock_reset?).to eq(false)
      end
    end

    context 'when there are settings, updated_ids and enterprises_to_reset' do
      let(:import_settings) do
        {
          settings: { 'something' => true },
          updated_ids: [0],
          enterprises_to_reset: [0]
        }
      end

      it 'returns true' do
        expect(settings.data_for_stock_reset?).to eq(true)
      end
    end
  end
end
