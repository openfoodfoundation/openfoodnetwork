require 'spec_helper'

describe ShopController, type: :controller, performance: true do
  let(:d) { create(:distributor_enterprise) }
  let(:enterprise_fee) { create(:enterprise_fee) }
  let(:order_cycle) { create(:simple_order_cycle, distributors: [d], coordinator_fees: [enterprise_fee]) }

  before do
    controller.stub(:current_distributor) { d }
    controller.stub(:current_order_cycle) { order_cycle }
  end

  describe "fetching products" do
    let(:exchange) { order_cycle.exchanges.to_enterprises(d).outgoing.first }
    let(:image) { File.open(File.expand_path('../../../app/assets/images/logo.jpg', __FILE__)) }

    before do
      11.times do
        p = create(:simple_product)
        p.set_property 'Organic Certified', 'NASAA 12345'
        v1 = create(:variant, product: p)
        v2 = create(:variant, product: p)
        Spree::Image.create! viewable_id: p.master.id, viewable_type: 'Spree::Variant', attachment: image

        exchange.variants << [v1, v2]
      end
    end

    it "returns products via json" do
      results = []
      4.times do |i|
        ActiveRecord::Base.connection.query_cache.clear
        Rails.cache.clear
        result = Benchmark.measure do
          xhr :get, :products
          response.should be_success
        end

        results << result.total if i > 0
        puts result
      end

      puts (results.sum / results.count * 1000).round 0
    end
  end
end
