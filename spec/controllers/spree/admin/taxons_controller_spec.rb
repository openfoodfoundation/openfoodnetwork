# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::TaxonsController do
  render_views

  let(:taxonomy) { create(:taxonomy) }
  let(:taxon) { create(:taxon, name: "Ruby", taxonomy: taxonomy) }
  let(:taxon2) { create(:taxon, name: "Rails", taxonomy: taxonomy) }

  before do
    allow(controller).to receive(:spree_current_user) { current_api_user }

    taxonomy.root.children << taxon
    taxonomy.root.children << taxon2
  end

  context "as an admin" do
    let(:current_api_user) { build(:admin_user) }

    it "can reorder taxons" do
      spree_post :update,
                 taxonomy_id: taxonomy.id,
                 id: taxon2.id,
                 taxon: { parent_id: taxonomy.root.id, position: 0 }

      expect(taxon2.reload.lft).to eq 2
      expect(Spree::Taxonomy.find(taxonomy.id).root.children.first).to eq(taxon2)
    end
  end
end
