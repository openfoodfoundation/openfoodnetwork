require 'spec_helper'

describe SitemapController, type: :controller do
  describe '#index' do
    it 'displays the four menu URLs' do
      spree_get :index
      expect(assigns(:page_urls)).to eq([shops_url, map_url, producers_url, groups_url])
    end

    it 'lists all hub enterprises' do
      hub = build(:enterprise, sells: 'any')
      allow(Enterprise).to receive(:is_hub).and_return([hub])

      spree_get :index
      expect(assigns(:enterprises)).to eq([hub])
    end

    it 'lists all enterprise groups' do
      group = build(:enterprise_group)
      allow(EnterpriseGroup).to receive(:all).and_return([group])

      spree_get :index
      expect(assigns(:groups)).to eq([group])
    end
  end
end
