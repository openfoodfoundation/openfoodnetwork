# frozen_string_literal: true

RSpec.describe 'sample_data.rake' do
  before do
    # Create seed data required by the sample data.
    create(:user)
    DefaultShippingCategory.find_or_create
  end

  it "creates some sample data to play with" do
    invoke_task "ofn:sample_data"

    expect(EnterpriseGroup.count).to eq 1
    expect(Customer.count).to eq 2
    expect(Spree::Order.count).to eq 5
  end
end
