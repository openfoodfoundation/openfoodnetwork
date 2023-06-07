# frozen_string_literal: true

require 'spec_helper'

describe Api::VariantSerializer do
  subject { Api::VariantSerializer.new variant }
  let(:variant) { create(:variant) }

  it "includes the expected attributes" do
    expect(subject.attributes.keys).
      to include(
        :id,
        :name_to_display,
        :on_hand,
        :name_to_display,
        :unit_to_display,
        :unit_value,
        :options_text,
        :on_demand,
        :price,
        :fees,
        :fees_name,
        :price_with_fees,
        :product_name,
        :tag_list # Used to apply tag rules
      )
  end

  describe "#unit_price_price" do
    context "without fees" do
      it "displays the price divided by the unit price denominator" do
        allow(subject).to receive_message_chain(:unit_price, :denominator) { 1000 }

        expect(subject.unit_price_price).to eq(variant.price / 1000)
      end
    end

    context "when the denominator returns nil" do
      it "returns the price" do
        allow(subject).to receive_message_chain(:unit_price, :denominator) { nil }

        expect(subject.unit_price_price).to eq(variant.price)
      end
    end
  end
end
