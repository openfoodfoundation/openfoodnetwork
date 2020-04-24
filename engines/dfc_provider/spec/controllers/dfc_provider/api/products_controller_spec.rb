require 'spec_helper'

describe DfcProvider::Api::ProductsController, type: :controller do
  render_views

  let(:enterprise) { create(:distributor_enterprise) }
  let(:product) do
    create(:simple_product, supplier: enterprise )
  end
  let!(:visible_inventory_item) do
    create(:inventory_item,
           enterprise: enterprise,
           variant: product.variants.first,
           visible: true)
  end

  describe('.index') do
    before do
      allow(controller)
        .to receive(:spree_current_user) { enterprise.owner }

      get :index, enterprise_id: enterprise.id
    end

    it 'is successful' do
      expect(response.status).to eq 200
    end

    it 'renders the related product' do
      expect(response.body)
        .to include("\"DFC:description\":\"#{product.variants.first.name}\"")
    end
  end
end
