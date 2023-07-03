# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe ProducerMailer, type: :mailer do
  let!(:zone) { create(:zone_with_member) }
  let!(:tax_rate) {
    create(:tax_rate, included_in_price: true, calculator: Calculator::DefaultTax.new, zone: zone,
                      amount: 0.1)
  }
  let!(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
  let(:s1) { create(:supplier_enterprise) }
  let(:s2) { create(:supplier_enterprise) }
  let(:s3) { create(:supplier_enterprise) }
  let(:d1) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:d2) { create(:distributor_enterprise) }
  let(:p1) {
    create(:product, name: "Zebra", price: 12.34, supplier: s1, tax_category_id: tax_category.id)
  }
  let(:p2) { create(:product, name: "Aardvark", price: 23.45, supplier: s2) }
  let(:p3) { create(:product, name: "Banana", price: 34.56, supplier: s1) }
  let(:p4) { create(:product, name: "coffee", price: 45.67, supplier: s1) }
  let(:p5) { create(:product, name: "Daffodil", price: 56.78, supplier: s1) }
  let(:p6) { create(:product, name: "Eggs", price: 67.89, supplier: s1) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let!(:incoming_exchange) {
    order_cycle.exchanges.create! sender: s1, receiver: d1, incoming: true,
                                  receival_instructions: 'Outside shed.'
  }
  let!(:outgoing_exchange) {
    order_cycle.exchanges.create! sender: d1, receiver: d1, incoming: false,
                                  pickup_time: 'Tue, 23rd Dec'
  }

  let!(:order) do
    order = create(:order, distributor: d1, order_cycle: order_cycle, state: 'complete')
    order.line_items << create(:line_item, quantity: 1, variant: p1.variants.first)
    order.line_items << create(:line_item, quantity: 2, variant: p1.variants.first)
    order.line_items << create(:line_item, quantity: 3, variant: p2.variants.first)
    order.line_items << create(:line_item, quantity: 2, variant: p4.variants.first)
    order.finalize!
    order.save
    order
  end
  let!(:order_incomplete) do
    order = create(:order, distributor: d1, order_cycle: order_cycle, state: 'payment')
    order.line_items << create(:line_item, variant: p3.variants.first)
    order.save
    order
  end
  let!(:order_canceled) do
    order = create(:order, distributor: d1, order_cycle: order_cycle, state: 'complete')
    order.line_items << create(:line_item, variant: p5.variants.first)
    order.finalize!
    order.cancel
    order.save
    order
  end

  let(:mail) { ProducerMailer.order_cycle_report(s1, order_cycle) }

  it "sets a reply-to of the oc coordinator's email" do
    expect(mail.reply_to).to eq [order_cycle.coordinator.contact.email]
  end

  it "includes the pickup time for each distributor" do
    expect(mail.body.encoded).to include "#{d1.name} (Tue, 23rd Dec)"
  end

  it "includes receival instructions" do
    expect(mail.body.encoded).to include 'Outside shed.'
  end

  it "cc's the oc coordinator" do
    expect(mail.cc).to eq [order_cycle.coordinator.contact.email]
  end

  it "contains an aggregated list of produce in alphabetical order" do
    expect(mail.body.encoded).to match(/coffee.+\n.+Zebra/)
    body_lines_including(mail, p1.name).each do |line|
      expect(line).to include 'QTY: 3'
      expect(line).to include '@ $10.00 = $30.00'
    end
    expect(body_as_html(mail).find("table.order-summary tr", text: p1.name))
      .to have_selector("td", text: "$30.00")
  end

  it "displays tax totals for each product" do
    # Tax for p1 line items
    expect(body_as_html(mail).find("table.order-summary tr", text: p1.name))
      .to have_selector("td.tax", text: "$2.73")
  end

  it "does not include incomplete orders" do
    expect(mail.body.encoded).not_to include p3.name
  end

  it "does not include canceled orders" do
    expect(mail.body.encoded).not_to include p5.name
  end

  context "when a cancelled order has been resumed" do
    let!(:order_resumed) do
      order = create(:order, distributor: d1, order_cycle: order_cycle, state: 'complete')
      order.line_items << create(:line_item, variant: p6.variants.first)
      order.finalize!
      order.cancel
      order.resume
      order.save!
      order
    end

    it "includes items from resumed orders" do
      expect(mail.body.encoded).to include p6.name
    end
  end

  it "includes the total" do
    expect(mail.body.encoded).to include 'Total: $50.00'
    expect(body_as_html(mail).find("tr.total-row"))
      .to have_selector("td", text: "$50.00")
  end

  it "sends no mail when the producer has no orders" do
    expect do
      ProducerMailer.order_cycle_report(s3, order_cycle).deliver_now
    end.to change(ActionMailer::Base.deliveries, :count).by(0)
  end

  it "shows a deleted variant's full name" do
    variant = p1.variants.first
    full_name = variant.full_name
    variant.delete

    expect(mail.body.encoded).to include(full_name)
  end

  it 'shows deleted products' do
    p1.delete
    expect(mail.body.encoded).to include(p1.name)
  end

  context 'when flag show_customer_names_to_suppliers is true' do
    before do
      order_cycle.coordinator.show_customer_names_to_suppliers = true
    end

    it "adds customer names table" do
      expect(body_as_html(mail).find(".order-summary.customer-order")).to_not be_nil
    end

    it "displays last name for each order" do
      product_name = order.line_items.first.product.name
      last_name = order.billing_address.lastname
      expect(body_as_html(mail).find("table.order-summary.customer-order tr",
                                     text: product_name)).to have_selector("td", text: last_name)
    end

    it "displays first name for each order" do
      product_name = order.line_items.first.product.name
      first_name = order.billing_address.firstname
      expect(body_as_html(mail).find("table.order-summary.customer-order tr",
                                     text: product_name)).to have_selector("td", text: first_name)
    end

    it "it orders list via last name" do
      create(:order, :with_line_item, distributor: d1, order_cycle: order_cycle, state: 'complete',
                                      bill_address: FactoryBot.create(:address, last_name: "Abby"))
      create(:order, :with_line_item, distributor: d1, order_cycle: order_cycle, state: 'complete',
                                      bill_address: FactoryBot.create(:address, last_name: "smith"))
      expect(mail.body.encoded).to match(/.*Abby.*Doe.*smith/m)
    end
  end

  context 'when flag show_customer_names_to_suppliers is false' do
    before do
      order_cycle.coordinator.show_customer_names_to_suppliers = false
    end

    it "does not add customer names table" do
      expect {
        body_as_html(mail).find(".order-summary.customer-order")
      }.to raise_error(Capybara::ElementNotFound)
    end
  end

  private

  def body_lines_including(mail, str)
    mail.body.to_s.lines.select { |line| line.include? str }
  end

  def body_as_html(mail)
    Capybara.string(mail.html_part.body.encoded)
  end
end
