# frozen_string_literal: true

require 'spec_helper'

describe Calculator::PriceSack do
  let(:calculator) do
    calculator = Calculator::PriceSack.new
    calculator.preferred_minimal_amount = 5
    calculator.preferred_normal_amount = 10
    calculator.preferred_discount_amount = 1
    calculator
  end
  let(:line_item) { build_stubbed(:line_item, price: price, quantity: 2) }

  it { is_expected.to validate_numericality_of(:preferred_minimal_amount) }
  it { is_expected.to validate_numericality_of(:preferred_normal_amount) }
  it { is_expected.to validate_numericality_of(:preferred_discount_amount) }

  context 'when the order amount is below preferred minimal' do
    let(:price) { 2 }

    it "uses the preferred normal amount" do
      expect(calculator.compute(line_item)).to eq(10)
    end
  end

  context 'when the order amount is above preferred minimal' do
    let(:price) { 6 }

    it "uses the preferred discount amount" do
      expect(calculator.compute(line_item)).to eq(1)
    end
  end

  context "preferred discount amount is float" do
    before do
      calculator.preferred_normal_amount = 10.4
      calculator.preferred_discount_amount = 1.2
    end

    context 'when the order amount is below preferred minimal' do
      let(:price) { 2 }

      it "uses the float preferred normal amount" do
        expect(calculator.compute(line_item)).to eq(10.4)
      end
    end

    context 'when the order amount is above preferred minimal' do
      let(:price) { 6 }

      it "uses the float preferred discount amount" do
        expect(calculator.compute(line_item)).to eq(1.2)
      end
    end
  end

  context "minimal amount is float" do
    before do
      calculator.preferred_minimal_amount = 16.5
      calculator.preferred_normal_amount = 5
      calculator.preferred_discount_amount = 1
      line_item.quantity = 2
    end

    context "with price bellow minimal amount" do
      let(:price) { 8 }

      it "returns the correct value of cost" do
        expect(calculator.compute(line_item)).to eq(5)
      end
    end

    context "with price above minimal amount" do
      let(:price) { 8.5 }

      it "returns the correct value of cost" do
        expect(calculator.compute(line_item)).to eq(1)
      end
    end
  end
end
