# frozen_string_literal: true

require 'spec_helper'

describe Spree::Gateway::SuccessfulResponse do
  describe "#initialize" do
    it "returns a succesful response" do
      response = described_class.new

      expect(response.success?).to eq(true)
      expect(response.message).to eq("")
      expect(response.params).to eq({})
    end
  end
end

