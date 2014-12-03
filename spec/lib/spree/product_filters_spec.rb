require 'spec_helper'

describe Spree::ProductFilters do
  context "distributor filter" do
    it "provides filtering for all distributors" do
      3.times { create(:distributor_enterprise) }
      Enterprise.is_distributor.sort.map { |d| [d.name, d.name] }.each do |distributor|
      	expect(Spree::ProductFilters.distributor_filter[:labels]).to include distributor
      end
    end
  end
end
