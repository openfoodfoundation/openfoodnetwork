# frozen_string_literal: true

RSpec.describe Spree::Admin::TaxonsController do
  render_views

  let!(:taxon) { create(:taxon, name: "Ruby") }
  let!(:taxon2) { create(:taxon, name: "Rails") }
  let(:valid_attributes) { attributes_for(:taxon) }

  before do
    allow(controller).to receive(:spree_current_user) { current_api_user }
  end

  describe 'admin user' do
    let(:current_api_user) { build(:admin_user) }

    it "can view all taxons" do
      spree_get :index

      expect(response).to have_http_status :ok
    end

    it "open taxon edit form" do
      spree_get :edit, { id: taxon.id }

      expect(response).to have_http_status :ok
    end

    it "open taxon edit form" do
      spree_get :new

      expect(response).to have_http_status :ok
    end

    context "create" do
      it "persist data with valid attributes" do
        spree_post :create, valid_attributes

        expect(Spree::Taxon.last.name).to eq valid_attributes[:name]
        expect(response).to have_http_status :found
      end

      it "returns error with invalid attributes" do
        spree_post :create, { name: '' }

        expect(Spree::Taxon.count).to eq 2
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "update" do
      let!(:new_taxon) { create(:taxon, valid_attributes) }
      it "persist data with valid attributes" do
        spree_post :update, id: new_taxon.id,
                            taxon: valid_attributes.merge({ name: 'Taxon name updated' })

        expect(new_taxon.reload.name).to eq 'Taxon name updated'
        expect(response).to have_http_status :found
      end

      it "returns error with invalid attributes" do
        spree_post :update, id: new_taxon.id,
                            taxon: { **valid_attributes, name: '' }

        expect(new_taxon.reload.name).to eq valid_attributes[:name]
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end
end
