# frozen_string_literal: true

RSpec.describe Spree::Admin::TaxonsController do
  render_views

  let!(:taxon) { create(:taxon, name: "Ruby") }
  let!(:taxon2) { create(:taxon, name: "Rails") }
  let(:valid_attributes) {
    { name_i18n: { I18n.default_locale.to_s => "Ruby on Rails" } }
  }

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
        spree_post :create, taxon: valid_attributes

        expect(Spree::Taxon.last.name).to eq "Ruby on Rails"
        expect(response).to have_http_status :found
      end

      it "returns error with invalid attributes" do
        spree_post :create, taxon: { name_i18n: { I18n.default_locale.to_s => '' } }

        expect(Spree::Taxon.count).to eq 2
        expect(response).to have_http_status :unprocessable_entity
      end

      it "stores translations for multiple locales" do
        spree_post :create, taxon: {
          name_i18n: { I18n.default_locale.to_s => "Vegetables", "es" => "Verduras" }
        }

        taxon = Spree::Taxon.last
        expect(taxon.name_i18n).to eq(
          { "es" => "Verduras", I18n.default_locale.to_s => "Vegetables" }
        )
        expect(taxon.name).to eq("Vegetables")
      end
    end

    context "update" do
      let!(:new_taxon) { create(:taxon, name: "Ruby on Rails") }

      it "persist data with valid attributes" do
        spree_post :update, id: new_taxon.id,
                            taxon: {
                              name_i18n: { I18n.default_locale.to_s => 'Taxon name updated' }
                            }

        expect(new_taxon.reload.name).to eq 'Taxon name updated'
        expect(response).to have_http_status :found
      end

      it "returns error with invalid attributes" do
        spree_post :update, id: new_taxon.id,
                            taxon: { name_i18n: { I18n.default_locale.to_s => '' } }

        expect(new_taxon.reload.name).to eq "Ruby on Rails"
        expect(response).to have_http_status :unprocessable_entity
      end

      it "updates translations for multiple locales" do
        spree_post :update, id: new_taxon.id, taxon: {
          name_i18n: { I18n.default_locale.to_s => "Vegetables", "es" => "Verduras" }
        }

        expect(new_taxon.reload.name_i18n).to eq(
          { "es" => "Verduras", I18n.default_locale.to_s => "Vegetables" }
        )
      end
    end
  end
end
