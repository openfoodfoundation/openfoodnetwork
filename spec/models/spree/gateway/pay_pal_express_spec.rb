# frozen_string_literal: true

require 'spec_helper'

describe Spree::Gateway::PayPalExpress, type: :model do
  describe "#authorize" do
    it "returns a succesful response" do
      response = subject.authorize(nil, nil, nil)
      expect(response).to be_kind_of(Spree::Gateway::SuccessfulResponse)
    end
  end
end
