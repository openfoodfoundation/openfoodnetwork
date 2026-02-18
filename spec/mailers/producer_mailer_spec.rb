# frozen_string_literal: true

require 'yaml'

RSpec.describe ProducerMailer do
  let!(:zone) { create(:zone_with_member) }
  let!(:tax_rate) {
    create(:tax_rate, included_in_price: true, calculator: Calculator::DefaultTax.new, zone:,
                      amount: 0.1)
  }
  let!(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
  let(:s1) { create(:supplier_enterprise) }
  let(:s2) { create(:supplier_enterprise) }
  let(:s3) { create(:supplier_enterprise) }
  let(:d1) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:d2) { create(:distributor_enterprise) }
  let(:p1) {
    create(:product, name: "Zebra", price: 12.34, supplier_id: s1.id,
                     tax_category_id: tax_category.id)
  }
  let(:p2) { create(:product, name: "Aardvark", price: 23.45, supplier_id: s2.id) }
  let(:p3) { create(:product, name: "Banana", price: 34.56, supplier_id: s1.id) }
  let(:p4) { create(:product, name: "coffee", price: 45.67, supplier_id: s1.id) }
  let(:p5) { create(:product, name: "Daffodil", price: 56.78, supplier_id: s1.id) }
  let(:p6) { create(:product, name: "Eggs", price: 67.89, supplier_id: s1.id) }
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
    order = create(:order, distributor: d1, order_cycle:, state: 'complete')
    order.line_items << create(:line_item, quantity: 1, variant: p1.variants.first)
    order.line_items << create(:line_item, quantity: 2, variant: p1.variants.first)
    order.line_items << create(:line_item, quantity: 3, variant: p2.variants.first)
    order.line_items << create(:line_item, quantity: 2, variant: p4.variants.first)
    order.finalize!
    order.save
    order
  end
  let!(:order_incomplete) do
    order = create(:order, distributor: d1, order_cycle:, state: 'payment')
    order.line_items << create(:line_item, variant: p3.variants.first)
    order.save
    order
  end
  let!(:order_canceled) do
    order = create(:order, distributor: d1, order_cycle:, state: 'complete')
    order.line_items << create(:line_item, variant: p5.variants.first)
    order.finalize!
    order.cancel
    order.save
    order
  end

  let(:mail) { ProducerMailer.order_cycle_report(s1, order_cycle) }
  let(:parsed_email) { Capybara::Node::Simple.new(mail.body.encoded) }

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
    rows = parsed_email.all('table.order-summary.line-items tbody tr:not(.total-row)')
    actual = rows.map do |row|
      row.all('td').map { |td| td.text.strip }
    end
    expected = [
      ['', 'coffee - 1g', '2', '$10.00', '$20.00', '$0.00'],
      ['', 'Zebra - 1g',  '3', '$10.00', '$30.00', '$2.73']
    ]
    expect(actual).to eq(expected)
  end

  it "displays tax totals for each product" do
    # Tax for p1 line items
    expect(parsed_email.find("table.order-summary tr", text: p1.name))
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
      order = create(:order, distributor: d1, order_cycle:, state: 'complete')
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
    expect(parsed_email.find("tr.total-row")).to have_selector("td", text: "$50.00")
  end

  it "sends no mail when the producer has no orders" do
    expect do
      ProducerMailer.order_cycle_report(s3, order_cycle).deliver_now
    end.to change { ActionMailer::Base.deliveries.count }.by(0)
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
      expect(parsed_email).to have_selector(".order-summary.customer-order")
    end

    it "displays last name and first name for each order" do
      last_name = order.billing_address.lastname
      first_name = order.billing_address.firstname
      row = parsed_email.find("table.order-summary.customer-order tbody tr")
      expect(row).to have_selector("td", text: last_name)
      expect(row).to have_selector("td", text: first_name)
    end

    it "it orders list via last name" do
      create(:order, :with_line_item, distributor: d1, order_cycle:, state: 'complete',
                                      bill_address: FactoryBot.create(:address, last_name: "Abby"))
      create(:order, :with_line_item, distributor: d1, order_cycle:, state: 'complete',
                                      bill_address: FactoryBot.create(:address, last_name: "smith"))
      expect(mail.body.encoded).to match(/.*Abby.*Doe.*smith/m)
    end

    context "validate business name" do
      let(:table_header) do
        parsed_email.find("table.order-summary.customer-order thead")
      end

      context "when no customer has customer code" do
        it 'should not display business name column' do
          expect(table_header).not_to have_selector("th", text: 'Business Name')
        end
      end

      context "when customer have code" do
        before { order.customer.update(code: 'Test Business Name') }

        it 'displays business name for the customer' do
          expect(table_header).to have_selector("th", text: 'Business Name')
          expect(parsed_email.find("table.order-summary.customer-order tbody tr"))
            .to have_selector("td", text: 'Test Business Name')
        end
      end
    end

    context "validate order number" do
      let(:table_header) do
        parsed_email.find("table.order-summary.customer-order thead")
      end

      it 'displays order number for the customer' do
        expect(table_header).to have_selector("th", text: 'Order Number')
        expect(
          parsed_email.find("table.order-summary.customer-order tbody tr")
        ).to have_selector("td", text: order.number)
      end
    end

    it "adds customer names in the table" do
      parsed_email.find(".order-summary.customer-order").tap do |table|
        expect(table).to have_selector("th", text: "First Name")
        expect(table).to have_selector("th", text: "Last Name")
      end
    end

    context "validate phone and email" do
      let(:table_header) do
        parsed_email.find("table.order-summary.customer-order thead")
      end

      it 'displays phone and email for the customer' do
        expect(table_header).to have_selector("th", text: 'Phone') &
                                have_selector("th", text: 'Email')
        expect(
          parsed_email.find("table.order-summary.customer-order tbody tr")
        ).to have_selector("td", text: order.billing_address.phone) &
             have_selector("td", text: order.customer.email)
      end
    end
  end

  context 'when flag show_customer_names_to_suppliers is false' do
    before do
      order_cycle.coordinator.show_customer_names_to_suppliers = false
    end

    it "does not add customer names, phone and email in the table" do
      parsed_email.find(".order-summary.customer-order").tap do |table|
        expect(table).not_to have_selector("th", text: "First Name")
        expect(table).not_to have_selector("th", text: "Last Name")
        expect(table).not_to have_selector("th", text: "Phone")
        expect(table).not_to have_selector("th", text: "Email")

        expect(parsed_email).not_to have_content order.billing_address.phone
        expect(parsed_email).not_to have_content order.customer.email
        expect(parsed_email).not_to have_content order.billing_address.lastname
        expect(parsed_email).not_to have_content order.billing_address.firstname
      end
    end
  end

  context "products from multiple suppliers" do
    before do
      order_cycle.exchanges.create! sender: s1, receiver: d2, incoming: true,
                                    receival_instructions: 'Community hall'
      order_cycle.exchanges.create! sender: d2, receiver: d2, incoming: false,
                                    pickup_time: 'Mon, 22nd Dec'
      order = create(:order, distributor: d2, order_cycle:, state: 'complete')
      order.line_items << create(:line_item, quantity: 3, variant: p1.variants.first)
      order.finalize!
      order.save
    end

    it "displays a supplier column" do
      expect(parsed_email.find(".order-summary"))
        .to have_selector("th", text: "Supplier")
    end

    context "when the show customer names to suppliers setting is enabled" do
      before { order_cycle.coordinator.update!(show_customer_names_to_suppliers: true) }

      it "displays a supplier column in the summary of orders grouped by customer" do
        expect(parsed_email.find(".customer-order"))
          .to have_selector("th", text: "Supplier")
      end
    end
  end

  context "products from only one supplier" do
    it "doesn't display a supplier column" do
      expect(parsed_email.find(".order-summary"))
        .not_to have_selector("th", text: "Supplier")
    end

    context "when the show customer names to suppliers setting is enabled" do
      before { order_cycle.coordinator.update!(show_customer_names_to_suppliers: true) }

      it "doesn't display a supplier column in the summary of orders grouped by customer" do
        expect(parsed_email.find(".customer-order"))
          .not_to have_selector("th", text: "Supplier")
      end
    end
  end
end
