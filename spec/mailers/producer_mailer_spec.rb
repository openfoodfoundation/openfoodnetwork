require 'spec_helper'
require 'yaml'

describe ProducerMailer do
  before do
    Spree::MailMethod.create!(
      environment: Rails.env,
      preferred_mails_from: 'spree@example.com'
    )
  end
  let!(:zone) { create(:zone_with_member) }
  let!(:tax_rate) { create(:tax_rate, included_in_price: true, calculator: Spree::Calculator::DefaultTax.new, zone: zone, amount: 0.1) }
  let!(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
  let(:s1) { create(:supplier_enterprise) }
  let(:s2) { create(:supplier_enterprise) }
  let(:s3) { create(:supplier_enterprise) }
  let(:d1) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:d2) { create(:distributor_enterprise) }
  let(:p1) { create(:product, price: 12.34, supplier: s1, tax_category: tax_category) }
  let(:p2) { create(:product, price: 23.45, supplier: s2) }
  let(:p3) { create(:product, price: 34.56, supplier: s1) }
  let(:p4) { create(:product, price: 45.67, supplier: s1) }
  let(:p5) { create(:product, price: 56.78, supplier: s1) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let!(:incoming_exchange) { order_cycle.exchanges.create! sender: s1, receiver: d1, incoming: true, receival_instructions: 'Outside shed.' }

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
  let(:mail) { ActionMailer::Base.deliveries.last }

  before do
    ActionMailer::Base.deliveries.clear
    ProducerMailer.order_cycle_report(s1, order_cycle).deliver
  end

  it "should send an email when an order cycle is closed" do
    ActionMailer::Base.deliveries.count.should == 1
  end

  it "sets a reply-to of the enterprise email" do
    mail.reply_to.should == [s1.email]
  end

  it "includes receival instructions" do
    mail.body.encoded.should include 'Outside shed.'
  end

  it "cc's the enterprise" do
    mail.cc.should == [s1.email]
  end

  it "contains an aggregated list of produce" do
    body_lines_including(mail, p1.name).each do |line|
      line.should include 'QTY: 3'
      line.should include '@ $10.00 = $30.00'
    end
    body_as_html(mail).find("table.order-summary tr", text: p1.name)
      .should have_selector("td", text: "$30.00")
  end

  it "displays tax totals for each product" do
    # Tax for p1 line items
    body_as_html(mail).find("table.order-summary tr", text: p1.name)
      .should have_selector("td.tax", text: "$2.73")
  end

  it "does not include incomplete orders" do
    mail.body.encoded.should_not include p3.name
  end

  it "does not include canceled orders" do
    mail.body.encoded.should_not include p5.name
  end

  it "includes the total" do
    mail.body.encoded.should include 'Total: $50.00'
    body_as_html(mail).find("tr.total-row")
      .should have_selector("td", text: "$50.00")
  end

  it "sends no mail when the producer has no orders" do
    expect do
      ProducerMailer.order_cycle_report(s3, order_cycle).deliver
    end.to change(ActionMailer::Base.deliveries, :count).by(0)
  end


  private

  def body_lines_including(mail, s)
    mail.body.to_s.lines.select { |line| line.include? s }
  end

  def body_as_html(mail)
    Capybara.string(mail.html_part.body.encoded)
  end
end
