# frozen_string_literal: true

RSpec.describe ProductImport::GroupBuyConverter do
  subject(:converted) { described_class.new(attrs).converted_attributes }

  describe "group_buy" do
    it "converts recognised values to booleans" do
      expect(described_class.new('group_buy' => "1").converted_attributes)
        .to eq('group_buy' => true)
      expect(described_class.new('group_buy' => " True ").converted_attributes)
        .to eq('group_buy' => true)
      expect(described_class.new('group_buy' => "FALSE").converted_attributes)
        .to eq('group_buy' => false)
      expect(described_class.new('group_buy' => "0").converted_attributes)
        .to eq('group_buy' => false)
    end

    it "keeps unrecognised values" do
      expect(described_class.new('group_buy' => "yes").converted_attributes)
        .to eq('group_buy' => "yes")
    end
  end

  describe "blank values" do
    let(:attrs) { { 'name' => "Potatoes", 'group_buy' => "", 'group_buy_unit_size' => nil } }

    it "removes them so the product's existing values are left unchanged" do
      expect(converted).to eq('name' => "Potatoes")
    end
  end
end
