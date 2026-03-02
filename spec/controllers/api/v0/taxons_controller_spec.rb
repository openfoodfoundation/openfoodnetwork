# frozen_string_literal: true

RSpec.describe Api::V0::TaxonsController do
  render_views

  let!(:taxon) { create(:taxon, name: "Ruby") }
  let!(:taxon2) { create(:taxon, name: "Rails") }
  let!(:attributes) {
    ["id", "name", "permalink", "position"]
  }

  before do
    allow(controller).to receive(:spree_current_user) { current_api_user }
  end

  context "as a normal user" do
    let(:current_api_user) { build(:user) }

    it "gets all taxons" do
      api_get :index

      json_names = json_response.pluck(:name)
      expect(json_names).to include(taxon.name, taxon2.name)
    end

    it "can search for a single taxon" do
      api_get :index, q: { name_cont: "Ruby" }

      expect(json_response.count).to eq(1)
      expect(json_response.first['name']).to eq "Ruby"
    end

    it "cannot create a new taxon if not an admin" do
      api_post :create, taxon: { name: "Location" }

      assert_unauthorized!
    end

    it "cannot update a taxon" do
      api_put :update, id: taxon.id,
                       taxon: { name: "I hacked your store!" }

      assert_unauthorized!
    end

    it "cannot delete a taxon" do
      api_delete :destroy, id: taxon.id

      assert_unauthorized!
    end
  end

  context "as an admin" do
    let(:current_api_user) { build(:admin_user) }

    it "can create" do
      api_post :create, taxon: { name: "Colors" }

      expect(attributes.all? { |a| json_response.include? a }).to be true
      expect(response).to have_http_status(:created)
    end

    it "cannot create a new taxon with invalid attributes" do
      api_post :create, taxon: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
      errors = json_response["errors"]

      expect(Spree::Taxon.last).to eq taxon2
      expect(errors['name']).to eq ["can't be blank"]
    end

    it "can destroy" do
      api_delete :destroy, id: taxon2.id

      expect(response).to have_http_status(:no_content)
    end
  end
end
