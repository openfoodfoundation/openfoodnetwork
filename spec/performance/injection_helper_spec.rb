require 'spec_helper'

describe InjectionHelper, type: :helper, performance: true do
  let(:oc) { create(:simple_order_cycle) }
  let(:relative_supplier) { create(:supplier_enterprise) }
  let(:relative_distributor) { create(:distributor_enterprise) }

  before do
    50.times do
      e = create(:enterprise)
      oc.distributors << e
      create(:enterprise_relationship, parent: e, child: relative_supplier)
      create(:enterprise_relationship, parent: e, child: relative_distributor)
    end
  end

  it "is performant in injecting enterprises" do
    results = []
    4.times do |i|
      ActiveRecord::Base.connection.query_cache.clear
      Rails.cache.clear
      result = Benchmark.measure { helper.inject_enterprises }
      results << result.total if i > 0
      puts result
    end

    puts (results.sum / results.count * 1000).round 0
  end
end
