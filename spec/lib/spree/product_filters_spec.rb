require 'spec_helper'

describe Spree::ProductFilters do
  context "distributor filter" do
    it "provides filtering for all distributors" do
      3.times { create(:distributor) }
      Spree::ProductFilters.distributor_filter[:labels].should == Distributor.all.map { |d| [d.name, d.name] }
    end
  end
end
