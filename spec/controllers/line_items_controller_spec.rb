require 'spec_helper'

describe LineItemsController do
  let(:item) { create(:line_item) }
  let(:item_with_oc) do
    order_cycle = create(:simple_order_cycle)
    distributor = create(:distributor_enterprise)
    item.order.order_cycle = order_cycle
    item.order.distributor = distributor
    item.order.save
    item
  end
  let(:distributor) do
    distributor = create(:distributor_enterprise)
    item.order.distributor = distributor
    item.order.save
    distributor
  end

  it "fails without line item id" do
    expect { delete :destroy }.to raise_error
  end

  it "denies deletion without order cycle" do
    request = { format: :json, id: item }
    delete :destroy, request
    expect(response.status).to eq 403
    expect { item.reload }.to_not raise_error
  end

  it "denies deletion without user" do
    request = { format: :json, id: item_with_oc }
    delete :destroy, request
    expect(response.status).to eq 403
    expect { item.reload }.to_not raise_error
  end

  it "denies deletion if editing is not allowed" do
    controller.stub spree_current_user: item.order.user
    request = { format: :json, id: item_with_oc }
    delete :destroy, request
    expect(response.status).to eq 403
    expect { item.reload }.to_not raise_error
  end

  it "deletes the line item if allowed" do
    controller.stub spree_current_user: item.order.user
    distributor = item_with_oc.order.distributor
    distributor.allow_order_changes = true
    distributor.save
    request = { format: :json, id: item_with_oc }
    delete :destroy, request
    expect(response.status).to eq 204
    expect { item.reload }.to raise_error
  end
end
