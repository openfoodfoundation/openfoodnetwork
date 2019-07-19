require 'spec_helper'

module Spree
  describe Api::TaxonsController do
    render_views

    let(:taxonomy) { create(:taxonomy) }
    let(:taxon) { create(:taxon, name: "Ruby", taxonomy: taxonomy) }
    let(:taxon2) { create(:taxon, name: "Rails", taxonomy: taxonomy) }
    let(:attributes) {
      ["id", "name", "pretty_name", "permalink", "position", "parent_id", "taxonomy_id"]
    }

    before do
      taxon2.children << create(:taxon, name: "3.2.2", taxonomy: taxonomy)
      taxon.children << taxon2
      taxonomy.root.children << taxon
    end

    context "as a normal user" do
      controller(Spree::Api::TaxonsController) do
        def spree_current_user
          FactoryBot.create(:user)
        end
      end

      it "gets all taxons for a taxonomy" do
        api_get :index, taxonomy_id: taxonomy.id

        expect(json_response.first['name']).to eq taxon.name
        children = json_response.first['taxons']
        expect(children.count).to eq 1
        expect(children.first['name']).to eq taxon2.name
        expect(children.first['taxons'].count).to eq 1
      end

      it "gets all taxons" do
        api_get :index

        expect(json_response.first['name']).to eq taxonomy.root.name
        children = json_response.first['taxons']
        expect(children.count).to eq 1
        expect(children.first['name']).to eq taxon.name
        expect(children.first['taxons'].count).to eq 1
      end

      it "can search for a single taxon" do
        api_get :index, q: { name_cont: "Ruby" }

        expect(json_response.count).to eq(1)
        expect(json_response.first['name']).to eq "Ruby"
      end

      it "gets a single taxon" do
        api_get :show, id: taxon.id, taxonomy_id: taxonomy.id

        expect(json_response['name']).to eq taxon.name
        expect(json_response['taxons'].count).to eq 1
      end

      it "can learn how to create a new taxon" do
        api_get :new, taxonomy_id: taxonomy.id
        expect(json_response["attributes"]).to eq(attributes.map(&:to_s))
        required_attributes = json_response["required_attributes"]
        expect(required_attributes).to include("name")
      end

      it "cannot create a new taxon if not an admin" do
        api_post :create, taxonomy_id: taxonomy.id, taxon: { name: "Location" }
        assert_unauthorized!
      end

      it "cannot update a taxon" do
        api_put :update, taxonomy_id: taxonomy.id,
                         id: taxon.id,
                         taxon: { name: "I hacked your store!" }
        assert_unauthorized!
      end

      it "cannot delete a taxon" do
        api_delete :destroy, taxonomy_id: taxonomy.id, id: taxon.id
        assert_unauthorized!
      end
    end

    context "as an admin" do
      controller(Spree::Api::TaxonsController) do
        def spree_current_user
          FactoryBot.create(:admin_user)
        end
      end

      it "can create" do
        api_post :create, taxonomy_id: taxonomy.id, taxon: { name: "Colors" }

        expect(attributes.all? { |a| json_response.include? a }).to be true
        expect(response.status).to eq(201)

        expect(taxonomy.reload.root.children.count).to eq 2

        expect(Spree::Taxon.last.parent_id).to eq taxonomy.root.id
        expect(Spree::Taxon.last.taxonomy_id).to eq taxonomy.id
      end

      it "cannot create a new taxon with invalid attributes" do
        api_post :create, taxonomy_id: taxonomy.id, taxon: {}
        expect(response.status).to eq(422)
        expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
        errors = json_response["errors"]

        expect(taxonomy.reload.root.children.count).to eq 1
      end

      it "cannot create a new taxon with invalid taxonomy_id" do
        api_post :create, taxonomy_id: 1000, taxon: { name: "Colors" }
        expect(response.status).to eq(422)
        expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")

        errors = json_response["errors"]
        expect(errors["taxonomy_id"]).not_to be_nil
        expect(errors["taxonomy_id"].first).to eq "Invalid taxonomy id."

        expect(taxonomy.reload.root.children.count).to eq 1
      end

      it "can destroy" do
        api_delete :destroy, taxonomy_id: taxonomy.id, id: taxon2.id
        expect(response.status).to eq(204)
      end
    end
  end
end
