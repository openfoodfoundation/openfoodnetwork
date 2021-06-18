# frozen_string_literal: true

require 'spec_helper'

describe Calculator::FlexiRate do
  let(:line_item) { build_stubbed(:line_item, quantity: quantity) }
  let(:calculator) do
    Calculator::FlexiRate.new(
      preferred_first_item: 2,
      preferred_additional_item: 1,
      preferred_max_items: 3
    )
  end

  context 'when nb of items ordered is above preferred max' do
    let(:quantity) { 4.0 }

    it "returns the first item rate" do
      expect(calculator.compute(line_item).round(2)).to eq(4.0)
    end
  end

  context 'when nb of items ordered is below preferred max' do
    let(:quantity) { 2.0 }

    it "returns the first item rate" do
      expect(calculator.compute(line_item).round(2)).to eq(3.0)
    end
  end

  it "allows creation of new object with all the attributes" do
    Calculator::FlexiRate.new(preferred_first_item: 1, preferred_additional_item: 1,
                              preferred_max_items: 1)
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module",
                    [:preferred_first_item, :preferred_additional_item]
  end
end
