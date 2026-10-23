# frozen_string_literal: true

RSpec.describe ProductImport::GroupBuyConverter do
  subject(:converted) { described_class.new(attrs).converted_attributes }

  describe "group_buy" do
    it "converts recognised values to booleans" do
      expect(described_class.new('group_buy' => "1").converted_attributes)
        .to eq('group_buy' => true)
      expect(described_class.new('group_buy' => " Yes ").converted_attributes)
        .to eq('group_buy' => true)
      expect(described_class.new('group_buy' => "FALSE").converted_attributes)
        .to eq('group_buy' => false)
      expect(described_class.new('group_buy' => "no").converted_attributes)
        .to eq('group_buy' => false)
    end

    it "keeps unrecognised values" do
      expect(described_class.new('group_buy' => "maybe").converted_attributes)
        .to eq('group_buy' => "maybe")
    end
  end

  describe "group_buy_unit_size" do
    it "converts numeric values to floats" do
      expect(described_class.new('group_buy_unit_size' => "10").converted_attributes)
        .to eq('group_buy_unit_size' => 10.0)
    end

    it "keeps non-numeric values" do
      expect(described_class.new('group_buy_unit_size' => "lots").converted_attributes)
        .to eq('group_buy_unit_size' => "lots")
    end
  end

  describe "blank values" do
    let(:attrs) { { 'name' => "Potatoes", 'group_buy' => "", 'group_buy_unit_size' => nil } }

    it "removes them so the product's existing values are left unchanged" do
      expect(converted).to eq('name' => "Potatoes")
    end
  end
end
