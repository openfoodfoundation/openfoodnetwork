require 'open_food_network/referer_parser'
require 'spec_helper'

module OpenFoodNetwork
  describe RefererParser do

    it "handles requests without referer" do
      RefererParser.path(nil).should be_nil
    end

    it "handles requests with referer" do
      RefererParser.path('http://example.org/').should eq('/')
    end

    it "handles requests with invalid referer" do
      RefererParser.path('this is not a URI').should be_nil
    end

    it "handles requests with known issue of referer" do
      RefererParser.path('http://example.org/##invalid-fragment').should eq('/')
    end
  end
end
