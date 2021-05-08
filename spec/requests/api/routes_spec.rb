# frozen_string_literal: true

# test a single endpoint to make sure the redirects are working as intended.
require 'spec_helper'

describe 'Orders Cycles endpoint', type: :request do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }

  context "requesting the latest version" do
    let(:path) { "/api/order_cycles/#{order_cycle.id}/products?distributor=#{distributor.id}" }

    it "redirects to v0, preserving URL params" do
      get path
      expect(response).to redirect_to(
        "/api/v0/order_cycles/#{order_cycle.id}/products?distributor=#{distributor.id}"
      )
    end
  end

  context "requesting a specific API version" do
    let(:path) { "/api/v0/order_cycles/#{order_cycle.id}/products?distributor=#{distributor.id}" }

    it "does not redirect" do
      get path
      expect(response.status).to eq(200)
    end
  end
end
