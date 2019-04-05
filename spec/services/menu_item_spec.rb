require 'spec_helper'

describe MenuItem do
  describe '#url' do
    context 'when the passed menu item does not exist' do
      it 'raises' do
        menu_item = described_class.new(0)
        expect { menu_item.url }.to raise_error(KeyError)
      end
    end

    context 'when the passed menu item has no configured URL' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('MENU_1_URL', shops_path)
          .and_return(shops_path)
      end

      it 'returns the default URL' do
        menu_item = described_class.new(1)
        expect(menu_item.url).to eq(shops_path)
      end

      it 'fetches the configuration value' do
        described_class.new(1).url

        expect(ENV)
          .to have_received(:fetch)
          .with('MENU_1_URL', shops_path)
      end
    end

    context 'when the passed menu item has a configured URL' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('MENU_4_URL', groups_path)
          .and_return('/foo')
      end

      it 'returns the configured URL' do
        menu_item = described_class.new(4)
        expect(menu_item.url).to eq('/foo')
      end

      it 'fetches the configuration value' do
        described_class.new(4).url

        expect(ENV)
          .to have_received(:fetch)
          .with('MENU_4_URL', groups_path)
      end
    end
  end

  describe '#name' do
    let(:menu_item) { described_class.new(1) }

    it 'returns the index prefixed with menu_' do
      expect(menu_item.name).to eq('menu_1')
    end
  end

  describe '#title' do
    let(:menu_item) { described_class.new(1) }

    it 'returns the appropriate title translation' do
      expect(menu_item.title).to eq(I18n.t('menu_1_title'))
    end
  end
end
