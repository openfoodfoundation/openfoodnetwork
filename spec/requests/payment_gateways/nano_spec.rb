# frozen_string_literal: true

RSpec.describe "/payment_gateways/nano/:payment_id" do
  let(:shop) { create(:distributor_enterprise) }
  let(:account) { "nano_1111111111111111111111111111111111111111111111111111hifc8npp" }
  let(:nano) {
    Spree::PaymentMethod::Nano.create!(
      name: "Nano",
      environment: "test",
      distributors: [shop],
      preferred_account: account,
      preferred_xno_per_unit: "2",
      preferred_node_url: "https://node.example.org/rpc",
    )
  }
  let!(:order) { create(:order_ready_for_confirmation, payment_method: nano) }
  let(:payment) { Spree::Payment.last.tap { |p| p.update!(source: nano, payment_method: nano) } }
  let(:block_hash) { "CD" * 32 }

  def stub_node(changes = {})
    reply = {
      "block_account" => "nano_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3",
      "amount" => nano.amount_raw(payment).to_s,
      "confirmed" => "true",
      "subtype" => "send",
      "local_timestamp" => (payment.created_at.to_i + 30).to_s,
      "contents" => {
        "link_as_account" => account,
        "representative" => nano.representative(payment),
      },
    }.merge(changes)
    node = instance_double(NanoPayment::Node, block_info: reply)
    allow(NanoPayment::Node).to receive(:new).and_return(node)
  end

  it "shows the amount, the account and the representative for this payment" do
    get payment_gateways_nano_path(payment_id: payment.id, order_token: order.token)

    expect(response).to have_http_status :ok
    expect(response.body).to include "#{nano.amount_xno(payment)} XNO"
    expect(response.body).to include account
    expect(response.body).to include nano.representative(payment)
  end

  it "needs the order token" do
    get payment_gateways_nano_path(payment_id: payment.id, order_token: "wrong")
    expect(response).to redirect_to "/checkout/payment"
  end

  it "completes the order with a bound send" do
    stub_node

    post payment_gateways_confirm_nano_path(payment_id: payment.id),
         params: { order_token: order.token, block_hash: }
    expect(response).to redirect_to(order_path(order, order_token: order.token))

    payment.reload
    expect(payment.state).to eq "completed"
    expect(payment.response_code).to eq block_hash
  end

  it "keeps the payment open when the send does not match" do
    stub_node("amount" => "1")

    post payment_gateways_confirm_nano_path(payment_id: payment.id),
         params: { order_token: order.token, block_hash: }
    expect(response).to have_http_status :unprocessable_entity

    payment.reload
    expect(payment.state).to eq "checkout"
    expect(payment.response_code).to be_nil
  end
end
