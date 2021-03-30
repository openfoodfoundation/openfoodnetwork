# frozen_string_literal: true

require 'spec_helper'

module Api
  describe V0::TaxonomiesController do
    render_views

    let(:taxonomy) { create(:taxonomy) }
    let(:taxon) { create(:taxon, name: "Ruby", taxonomy: taxonomy) }
    let(:taxon2) { create(:taxon, name: "Rails", taxonomy: taxonomy) }
    let(:attributes) { [:id, :name] }

    before do
      allow(controller).to receive(:spree_current_user) { current_api_user }

      taxon2.children << create(:taxon, name: "3.2.2", taxonomy: taxonomy)
      taxon.children << taxon2
      taxonomy.root.children << taxon
    end

    context "as a normal user" do
      let(:current_api_user) { build(:user) }

      it "gets the jstree-friendly version of a taxonomy" do
        api_get :jstree, id: taxonomy.id

        expect(json_response["data"]).to eq(taxonomy.root.name)
        expect(json_response["attr"]).to eq("id" => taxonomy.root.id, "name" => taxonomy.root.name)
        expect(json_response["state"]).to eq("closed")
      end
    end
  end
end
