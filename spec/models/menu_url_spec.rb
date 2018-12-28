require 'spec_helper'

describe MenuURL do
  describe '#to_s' do
    context 'when the passed menu item does not exist' do
      it 'raises' do
        menu_url = described_class.new('menu_0')
        expect { menu_url.to_s }.to raise_error(KeyError)
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
        menu_url = described_class.new('menu_1')
        expect(menu_url.to_s).to eq(shops_path)
      end

      it 'fetches the configuration value' do
        described_class.new('menu_1').to_s

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
        menu_url = described_class.new('menu_4')
        expect(menu_url.to_s).to eq('/foo')
      end

      it 'fetches the configuration value' do
        described_class.new('menu_4').to_s

        expect(ENV)
          .to have_received(:fetch)
          .with('MENU_4_URL', groups_path)
      end
    end
  end
end
