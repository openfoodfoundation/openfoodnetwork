# frozen_string_literal: true

require 'spec_helper'

describe Api::Admin::ProductSerializer do
  let(:product) { create(:simple_product) }
  let(:serializer) { described_class.new(product) }

  it "serializes a product" do
    expect(serializer.to_json).to match(product.name)
  end
end
