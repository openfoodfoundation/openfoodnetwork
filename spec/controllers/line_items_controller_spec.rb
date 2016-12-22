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

  it "lists bought items" do
    item.order.finalize!
    controller.stub spree_current_user: item.order.user
    controller.stub current_order_cycle: item_with_oc.order.order_cycle
    controller.stub current_distributor: item_with_oc.order.distributor
    get :index, { format: :json }
    expect(response.status).to eq 200
    json_response = JSON.parse(response.body)
    expect(json_response.length).to eq 1
    expect(json_response[0]['id']).to eq item.id
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

  it "updates fees" do
    Spree::Config.shipment_inc_vat = true
    Spree::Config.shipping_tax_rate = 0.25
    distributor = create(:distributor_enterprise, charges_sales_tax: true, allow_order_changes: true)
    shipping_fee = 3
    payment_fee = 5
    order = create(:completed_order_with_fees, distributor: distributor, shipping_fee: shipping_fee, payment_fee: payment_fee)

    # Sanity check fees
    item_num = order.line_items.length
    initial_fees = item_num * (shipping_fee + payment_fee)
    expect(order.adjustment_total).to eq initial_fees
    expect(order.shipment.adjustment.included_tax).to eq 1.2

    # Delete the item
    item = order.line_items.first
    controller.stub spree_current_user: order.user
    request = { format: :json, id: item }
    delete :destroy, request
    expect(response.status).to eq 204

    # Check the fees again
    order.reload
    order.shipment.reload
    expect(order.adjustment_total).to eq initial_fees - shipping_fee - payment_fee
    expect(order.shipment.adjustment.included_tax).to eq 0.6
  end
end
