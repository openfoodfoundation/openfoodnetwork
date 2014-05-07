require 'spec_helper'

describe Spree::ProductFilters do
  context "distributor filter" do
    it "provides filtering for all distributors" do
      3.times { create(:distributor_enterprise) }
      Spree::ProductFilters.distributor_filter[:labels].should == Enterprise.is_distributor.sort.map { |d| [d.name, d.name] }
    end
  end
end
