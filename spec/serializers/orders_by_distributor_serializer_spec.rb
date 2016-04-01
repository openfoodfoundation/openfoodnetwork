require 'spec_helper'

describe Api::OrdersByDistributorSerializer do

  # Banged lets ensure entered into test database
  let!(:distributor1) { create(:distributor_enterprise) }
  let!(:distributor2) { create(:distributor_enterprise) }
  let!(:user) { create(:user)}
  let!(:d1o1) { create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 10000)}
  let!(:d1o2) { create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 5000)}
  let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user_id: user.id)}

  before do
    @data = Enterprise.includes(:distributed_orders).where(enterprises: {id: user.enterprises_ordered_from }, spree_orders: {state: :complete, user_id: user.id}).to_a
    @serializer = ActiveModel::ArraySerializer.new(@data, {each_serializer: Api::OrdersByDistributorSerializer})
  end

  it "serializes orders" do
    expect(@serializer.to_json).to match "distributed_orders"
  end

  it "serializes the balance for each distributor" do
    expect(@serializer.serializable_array[0].keys).to include :balance
    # Would be good to test adding up balance properly but can't get a non-zero total from the factories...
    expect(@serializer.serializable_array[0][:balance]).to eq "0.00"
  end

end
