# frozen_string_literal: true

RSpec.describe Api::VariantSerializer do
  subject { described_class.new variant }
  let(:variant) { create(:variant, price: 10.00) }

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
        :tag_list, # Used to apply tag rules
        :unit_price_price,
        :unit_price_unit
      )
  end
end
