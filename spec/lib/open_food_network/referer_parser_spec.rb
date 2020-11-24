# frozen_string_literal: false

require 'open_food_network/referer_parser'
require 'spec_helper'

module OpenFoodNetwork
  describe RefererParser do
    it "handles requests without referer" do
      expect(RefererParser.path(nil)).to be_nil
    end

    it "handles requests with referer" do
      expect(RefererParser.path('http://example.org/')).to eq('/')
    end

    it "handles requests with invalid referer" do
      expect(RefererParser.path('this is not a URI')).to be_nil
    end

    it "handles requests with known issue of referer" do
      expect(RefererParser.path('http://example.org/##invalid-fragment')).to eq('/')
    end
  end
end
