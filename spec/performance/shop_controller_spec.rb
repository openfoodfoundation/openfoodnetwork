# frozen_string_literal: true

require 'spec_helper'

xdescribe ShopController, type: :controller, performance: true do
  include FileHelper

  let(:d) { create(:distributor_enterprise) }
  let(:enterprise_fee) { create(:enterprise_fee) }
  let(:order_cycle) {
    create(:simple_order_cycle, distributors: [d], coordinator_fees: [enterprise_fee])
  }

  before do
    allow(controller).to receive(:current_distributor) { d }
    allow(controller).to receive(:current_order_cycle) { order_cycle }
    Spree::Config.currency = 'AUD'
  end

  describe "fetching products" do
    let(:exchange) { order_cycle.exchanges.to_enterprises(d).outgoing.first }
    let(:image) { white_logo_file }
    let(:cache_key_patterns) do
      [
        'api\/taxon_serializer\/spree\/taxons',
        'enterprise'
      ]
    end

    before do
      11.times do
        p = create(:simple_product)
        p.set_property 'Organic Certified', 'NASAA 12345'
        v1 = create(:variant, product: p)
        v2 = create(:variant, product: p)
        Spree::Image.create! viewable_id: p.master.id, viewable_type: 'Spree::Variant',
                             attachment: image

        exchange.variants << [v1, v2]
      end
    end

    it "returns products via json" do
      pending("fixing failing performance specs")
      results = multi_benchmark(3, cache_key_patterns: cache_key_patterns) do
        get :products, xhr: true
        expect(response.status).to eq 200
      end
    end
  end
end
