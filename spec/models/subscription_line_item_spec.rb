# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionLineItem, model: true do
  describe "validations" do
    it "requires a subscription" do
      expect(subject).to validate_presence_of :subscription
    end

    it "requires a variant" do
      expect(subject).to validate_presence_of :variant
    end

    it "requires a integer for quantity" do
      expect(subject).to validate_numericality_of(:quantity).only_integer
    end
  end
end
