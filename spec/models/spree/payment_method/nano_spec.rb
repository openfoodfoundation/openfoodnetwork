# frozen_string_literal: true

RSpec.describe Spree::PaymentMethod::Nano do
  subject(:nano) {
    Spree::PaymentMethod::Nano.create!(
      name: "Nano",
      environment: "test",
      preferred_account: account,
      preferred_xno_per_unit: "2.5",
      preferred_node_url: "https://node.example.org/rpc",
    )
  }
  let(:account) { "nano_1111111111111111111111111111111111111111111111111111hifc8npp" }
  let(:payer) { "nano_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3" }
  let(:block_hash) { "AB" * 32 }
  let(:order) { create(:order_ready_for_confirmation, payment_method: nano) }
  let(:payment) { order.payments.last }

  def send_block(payment, changes = {})
    {
      "block_account" => payer,
      "amount" => nano.amount_raw(payment).to_s,
      "confirmed" => "true",
      "subtype" => "send",
      "local_timestamp" => (payment.created_at.to_i + 30).to_s,
      "contents" => {
        "link_as_account" => account,
        "representative" => nano.representative(payment),
      },
    }.merge(changes)
  end

  def stub_node(reply)
    node = instance_double(NanoPayment::Node, block_info: reply)
    allow(NanoPayment::Node).to receive(:new).and_return(node)
  end

  it "is offered only once account, price and node are valid" do
    expect(nano).to be_configured
    expect(Spree::PaymentMethod::Nano.new).not_to be_configured
  end

  it "refuses an account with a wrong checksum" do
    nano.preferred_account = account.sub(/p\z/, "q")
    expect(nano).not_to be_valid
  end

  it "refuses a price that is not a positive decimal" do
    nano.preferred_xno_per_unit = "0"
    expect(nano).not_to be_valid
  end

  it "derives the amount in raw from the payment amount and the price" do
    payment.update!(amount: BigDecimal("10.40"))
    expect(nano.amount_raw(payment)).to eq 26 * 10**30
    expect(nano.amount_xno(payment)).to eq "26"
  end

  it "gives each payment its own representative" do
    other = create(:payment, order:, payment_method: nano, amount: payment.amount)
    expect(nano.representative(other)).not_to eq nano.representative(payment)
    expect(NanoPayment::Address.valid?(nano.representative(payment))).to be true
  end

  describe "#external_payment_url" do
    it "points to the payment page with the order token" do
      url = nano.external_payment_url(order:)

      expect(url).to eq "/payment_gateways/nano/#{payment.id}?order_token=#{order.token}"
    end
  end

  describe "#check_block" do
    it "accepts a confirmed send bound to this payment" do
      stub_node(send_block(payment))
      expect(nano.check_block(payment, block_hash.downcase)).to be_ok
    end

    it "refuses a send of another amount" do
      stub_node(send_block(payment, "amount" => (nano.amount_raw(payment) - 1).to_s))
      expect(nano.check_block(payment, block_hash).error).to eq :wrong_amount
    end

    it "refuses a send made for another payment" do
      other = create(:payment, order:, payment_method: nano, amount: payment.amount)
      stub_node(send_block(other))
      expect(nano.check_block(payment, block_hash).error).to eq :not_bound
    end

    it "refuses a block hash already stored on another payment" do
      create(:payment, order:, payment_method: nano, response_code: block_hash)
      stub_node(send_block(payment))
      expect(nano.check_block(payment, block_hash).error).to eq :already_used
    end

    it "refuses a malformed hash without asking the node" do
      expect(NanoPayment::Node).not_to receive(:new)
      expect(nano.check_block(payment, "not-a-hash").error).to eq :invalid_hash
    end

    it "reports an unreachable node" do
      node = instance_double(NanoPayment::Node)
      allow(node).to receive(:block_info).and_raise(NanoPayment::Node::Error, "down")
      allow(NanoPayment::Node).to receive(:new).and_return(node)
      expect(nano.check_block(payment, block_hash).error).to eq :node_unavailable
    end
  end

  describe "#purchase" do
    it "succeeds for the stored block hash" do
      payment.update!(response_code: block_hash)
      stub_node(send_block(payment))

      response = nano.purchase(nil, nano, { payment: })
      expect(response).to be_success
      expect(response.authorization).to eq block_hash
    end

    it "fails when the block does not pay this payment" do
      payment.update!(response_code: block_hash)
      stub_node(send_block(payment, "confirmed" => "false"))

      expect(nano.purchase(nil, nano, { payment: })).not_to be_success
    end
  end
end
