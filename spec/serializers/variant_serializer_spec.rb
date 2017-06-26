require 'spec_helper'

describe Api::VariantSerializer do
  
  subject { Api::VariantSerializer.new variant }
  let(:variant) { create(:variant) }

  it "includes the expected attributes " do 
    expect(subject.attributes.keys).
    to include(
        :id,
        :name_to_display, 
        :is_master, 
        :count_on_hand, 
        :name_to_display, 
        :unit_to_display, 
        :unit_value,
        :options_text, 
        :on_demand, 
        :price, 
        :fees, 
        :price_with_fees, 
        :product_name
      )
  end

end
