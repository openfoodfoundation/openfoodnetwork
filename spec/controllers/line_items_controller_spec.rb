require 'spec_helper'

describe LineItemsController do
  let(:item) { create(:line_item) }
  let(:item_with_oc) do
    order_cycle = create(:simple_order_cycle)
    item.order.order_cycle = order_cycle
    item.order.save
    item
  end

  it "fails without line item id" do
    expect { delete :destroy }.to raise_error
  end

  it "denies deletion without order cycle" do
    request = { format: :json, id: item }
    delete :destroy, request
    expect(response.status).to be 403
    expect { item.reload }.to_not raise_error
  end

  it "denies deletion without user" do
    request = { format: :json, id: item_with_oc }
    delete :destroy, request
    expect(response.status).to be 403
    expect { item.reload }.to_not raise_error
  end

  it "deletes the line item" do
    controller.stub spree_current_user: item.order.user
    request = { format: :json, id: item_with_oc }
    delete :destroy, request
    expect(response.status).to be 204
    expect { item.reload }.to raise_error
  end
end
