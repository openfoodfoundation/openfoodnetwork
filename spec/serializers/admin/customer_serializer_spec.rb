describe Api::Admin::CustomerSerializer do
  let(:customer) { create(:customer, tag_list: "one, two, three") }
  let!(:tag_rule) { create(:tag_rule, enterprise: customer.enterprise, preferred_customer_tags: "two") }

  it "serializes a customer with tags" do
    tag_rule_mapping = TagRule.mapping_for(Enterprise.where(id: customer.enterprise_id))
    serializer = Api::Admin::CustomerSerializer.new customer, tag_rule_mapping: tag_rule_mapping
    result = JSON.parse(serializer.to_json)
    expect(result['email']).to eq customer.email
    tags = result['tags']
    expect(tags.length).to eq 3
    expect(tags[0]).to eq({ "text" => 'one', "rules" => nil })
    expect(tags[1]).to eq({ "text" => 'two', "rules" => 1 })

    expect(result['bill_address']['id']).to eq customer.bill_address.id
    expect(result['bill_address']['address1']).to eq customer.bill_address.address1
    expect(result['ship_address']).to be nil
  end

  it 'serializes a customer without tag_rule_mapping' do
    serializer = Api::Admin::CustomerSerializer.new customer
    result = JSON.parse(serializer.to_json)

    result['tags'].each do |tag|
      expect(tag['rules']).to be nil
    end
  end
end
