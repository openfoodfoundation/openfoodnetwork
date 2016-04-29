describe Api::Admin::CustomerSerializer do
  let(:customer) { create(:customer, tag_list: "one, two, three") }
  let!(:tag_rule) { create(:tag_rule, enterprise: customer.enterprise, preferred_customer_tags: "two") }

  it "serializes a customer" do
    serializer = Api::Admin::CustomerSerializer.new customer
    result = JSON.parse(serializer.to_json)
    expect(result['email']).to eq customer.email
    tags = result['tags']
    expect(tags.length).to eq 3
    expect(tags[0]).to eq({ "text" => 'one', "rules" => nil })
    expect(tags[1]).to eq({ "text" => 'two', "rules" => 1 })
  end
end
