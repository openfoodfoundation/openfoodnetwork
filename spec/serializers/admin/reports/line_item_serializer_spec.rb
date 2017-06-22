require 'spec_helper'
describe Api::Admin::Reports::LineItemSerializer do
  let(:order) { create(:completed_order_with_totals) }
  let(:line_item) { build(:line_item) }

  before { order.line_items << line_item }

  describe 'instance methods' do
    subject { Api::Admin::Reports::LineItemSerializer.new line_item }

    it '#cost' do
      expect(subject.cost).to eq 10.0
    end

    it '#cost_with_fees' do
      expect(subject.cost_with_fees).to eq 10.0
    end

    it '#scaled_final_weight_volume' do
      expect(subject.scaled_final_weight_volume.to_f).to eq 1.0
    end

    it '#total_available' do
      expect(subject.total_available).to eq 0.0
    end

    it '#units_required' do
      expect(subject.units_required).to eq 0
    end

    it '#remainder' do
      expect(subject.remainder).to eq ""
    end

    it '#max_quantity_excess' do
      expect(subject.max_quantity_excess.to_f).to eq 0.0
    end

    it '#total_units' do
      expect(subject.remainder).to eq ""
    end

    it '#paid?' do
      expect(subject.paid?).to eq "No"
    end

  end
  # let(:customer) { create(:customer, tag_list: "one, two, three") }
  # let!(:tag_rule) { create(:tag_rule, enterprise: customer.enterprise, preferred_customer_tags: "two") }

  # it "serializes a customer with tags" do
  #   tag_rule_mapping = TagRule.mapping_for(Enterprise.where(id: customer.enterprise_id))
  #   serializer = Api::Admin::CustomerSerializer.new customer, tag_rule_mapping: tag_rule_mapping
  #   result = JSON.parse(serializer.to_json)
  #   expect(result['email']).to eq customer.email
  #   tags = result['tags']
  #   expect(tags.length).to eq 3
  #   expect(tags[0]).to eq({ "text" => 'one', "rules" => nil })
  #   expect(tags[1]).to eq({ "text" => 'two', "rules" => 1 })

  #   expect(result['bill_address']['id']).to eq customer.bill_address.id
  #   expect(result['bill_address']['address1']).to eq customer.bill_address.address1
  #   expect(result['ship_address']).to be nil
  # end

  # it 'serializes a customer without tag_rule_mapping' do
  #   serializer = Api::Admin::CustomerSerializer.new customer
  #   result = JSON.parse(serializer.to_json)

  #   result['tags'].each do |tag|
  #     expect(tag['rules']).to be nil
  #   end
  # end
end
