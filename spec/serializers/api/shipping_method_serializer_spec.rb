# frozen_string_literal: true

require 'spec_helper'

describe Api::ShippingMethodSerializer do
  let(:shipping_method) { create(:shipping_method) }

  it "serializes a test shipping_method" do
    serializer = Api::ShippingMethodSerializer.new shipping_method

    expect(serializer.to_json).to match(shipping_method.name)
  end

  it "can serialize all configured shipping method calculators" do
    Rails.application.config.spree.calculators.shipping_methods.each do |calculator|
      shipping_method.calculator = calculator.new
      serializer = Api::ShippingMethodSerializer.new shipping_method
      allow(serializer).to receive(:options).and_return(current_order: create(:order))

      expect(serializer.price).to eq(0.0)
    end
  end
end
