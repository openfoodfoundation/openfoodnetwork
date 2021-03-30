# frozen_string_literal: true

require 'spec_helper'

describe Api::V0::ShopsController, type: :controller do
  include AuthenticationHelper
  render_views

  context "as a non-authenticated user" do
    let!(:hub) {
      create(:distributor_enterprise, with_payment_and_shipping: true, name: 'Shopfront Test Hub')
    }
    let!(:producer) { create(:supplier_enterprise, name: 'Shopfront Test Producer') }
    let!(:category) { create(:taxon, name: 'Fruit') }
    let!(:product) { create(:product, supplier: producer, primary_taxon: category ) }
    let!(:relationship) { create(:enterprise_relationship, parent: hub, child: producer) }
    let!(:closed_hub1) { create(:distributor_enterprise) }
    let!(:closed_hub2) { create(:distributor_enterprise) }

    before do
      allow(controller).to receive(:spree_current_user) { nil }
    end

    describe "#show" do
      it "returns shopfront data for an enterprise" do
        get :show, params: { id: producer.id }

        expect(json_response['name']).to eq 'Shopfront Test Producer'
        expect(json_response['hubs'][0]['name']).to eq 'Shopfront Test Hub'
        expect(json_response['supplied_taxons'][0]['name']).to eq 'Fruit'
      end
    end

    describe "#closed_shops" do
      it "returns data for all closed shops" do
        get :closed_shops, params: {}

        expect(json_response).not_to match hub.name

        response_ids = json_response.map { |shop| shop['id'] }
        expect(response_ids).to contain_exactly(closed_hub1.id, closed_hub2.id)
      end
    end
  end
end
