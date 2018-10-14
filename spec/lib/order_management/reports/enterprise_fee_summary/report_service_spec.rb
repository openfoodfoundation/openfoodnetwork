require "spec_helper"

require "order_management/reports/enterprise_fee_summary/report_service"
require "order_management/reports/enterprise_fee_summary/parameters"

describe OrderManagement::Reports::EnterpriseFeeSummary::ReportService do
  let(:report_klass) { OrderManagement::Reports::EnterpriseFeeSummary }

  let!(:shipping_method) do
    create(:shipping_method, name: "Sample Shipping Method", calculator: per_item_calculator(1.0))
  end

  let!(:payment_method) do
    create(:payment_method, name: "Sample Payment Method", calculator: per_item_calculator(2.0))
  end

  let!(:distributor) do
    create(:distributor_enterprise, name: "Sample Distributor").tap do |enterprise|
      payment_method.distributors << enterprise
      shipping_method.distributors << enterprise
    end
  end
  let!(:distributor_fees) do
    [
      create(:enterprise_fee, name: "Included Distributor Fee 1", enterprise: distributor,
                              fee_type: "admin", calculator: per_item_calculator(4.0),
                              tax_category: prepare_tax_category("Sample Distributor Tax")),
      create(:enterprise_fee, name: "Included Distributor Fee 2", enterprise: distributor,
                              fee_type: "sales", calculator: per_item_calculator(8.0),
                              inherits_tax_category: true),
      create(:enterprise_fee, name: "Excluded Distributor Fee", enterprise: distributor,
                              fee_type: "sales", calculator: per_item_calculator(16.0))
    ]
  end

  let!(:producer) { create(:supplier_enterprise, name: "Sample Producer") }
  let!(:producer_fees) do
    [
      create(:enterprise_fee, name: "Excluded Producer Fee", enterprise: producer,
                              fee_type: "admin", calculator: per_item_calculator(32.0)),
      create(:enterprise_fee, name: "Included Producer Fee 1", enterprise: producer,
                              fee_type: "sales", calculator: per_item_calculator(64.0),
                              tax_category: prepare_tax_category("Sample Producer Tax")),
      create(:enterprise_fee, name: "Included Producer Fee 2", enterprise: producer,
                              fee_type: "sales", calculator: per_item_calculator(128.0),
                              inherits_tax_category: true)
    ]
  end

  let!(:coordinator) { create(:enterprise, name: "Sample Coordinator") }
  let!(:coordinator_fees) do
    [
      create(:enterprise_fee, name: "Excluded Coordinator Fee", enterprise: coordinator,
                              fee_type: "admin", calculator: per_item_calculator(256.0)),
      create(:enterprise_fee, name: "Included Coordinator Fee 1", enterprise: coordinator,
                              fee_type: "admin", calculator: per_item_calculator(512.0),
                              tax_category: prepare_tax_category("Sample Coordinator Tax")),
      create(:enterprise_fee, name: "Included Coordinator Fee 2", enterprise: coordinator,
                              fee_type: "sales", calculator: per_item_calculator(1024.0),
                              inherits_tax_category: true)
    ]
  end

  let!(:order_cycle) do
    create(:simple_order_cycle, coordinator: coordinator,
                                coordinator_fees: [coordinator_fees[1], coordinator_fees[2]])
  end

  let!(:product) { create(:product, tax_category: prepare_tax_category("Sample Product Tax")) }

  let!(:variant) do
    prepare_variant(incoming_exchange_fees: [producer_fees[1], producer_fees[2]],
                    outgoing_exchange_fees: [distributor_fees[0], distributor_fees[1]])
  end

  let!(:customer) { create(:customer, name: "Sample Customer") }
  let!(:another_customer) { create(:customer, name: "Another Customer") }

  describe "grouping and sorting of entries" do
    let!(:customer_order) { prepare_order(customer: customer) }
    let!(:second_customer_order) { prepare_order(customer: customer) }
    let!(:other_customer_order) { prepare_order(customer: another_customer) }

    let(:parameters) { OrderManagement::Reports::EnterpriseFeeSummary::Parameters.new }
    let(:service) { described_class.new(parameters, nil) }

    it "groups and sorts entries correctly" do
      totals = service.enterprise_fee_type_totals

      expect(totals.list.length).to eq(16)

      # Data is sorted by the following, in order:
      # * fee_type
      # * enterprise_name
      # * fee_name
      # * customer_name
      # * fee_placement
      # * fee_calculated_on_transfer_through_name
      # * tax_category_name
      # * total_amount

      expected_result = [
        ["Admin", "Sample Coordinator", "Included Coordinator Fee 1", "Another Customer",
         "Coordinator", "All", "Sample Coordinator Tax", "512.00"],
        ["Admin", "Sample Coordinator", "Included Coordinator Fee 1", "Sample Customer",
         "Coordinator", "All", "Sample Coordinator Tax", "1024.00"],
        ["Admin", "Sample Distributor", "Included Distributor Fee 1", "Another Customer",
         "Outgoing", "Sample Coordinator", "Sample Distributor Tax", "4.00"],
        ["Admin", "Sample Distributor", "Included Distributor Fee 1", "Sample Customer",
         "Outgoing", "Sample Coordinator", "Sample Distributor Tax", "8.00"],
        ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Another Customer",
         nil, nil, nil, "2.00"],
        ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Sample Customer",
         nil, nil, nil, "4.00"],
        ["Sales", "Sample Coordinator", "Included Coordinator Fee 2", "Another Customer",
         "Coordinator", "All", "Sample Product Tax", "1024.00"],
        ["Sales", "Sample Coordinator", "Included Coordinator Fee 2", "Sample Customer",
         "Coordinator", "All", "Sample Product Tax", "2048.00"],
        ["Sales", "Sample Distributor", "Included Distributor Fee 2", "Another Customer",
         "Outgoing", "Sample Coordinator", "Sample Product Tax", "8.00"],
        ["Sales", "Sample Distributor", "Included Distributor Fee 2", "Sample Customer",
         "Outgoing", "Sample Coordinator", "Sample Product Tax", "16.00"],
        ["Sales", "Sample Producer", "Included Producer Fee 1", "Another Customer",
         "Incoming", "Sample Producer", "Sample Producer Tax", "64.00"],
        ["Sales", "Sample Producer", "Included Producer Fee 1", "Sample Customer",
         "Incoming", "Sample Producer", "Sample Producer Tax", "128.00"],
        ["Sales", "Sample Producer", "Included Producer Fee 2", "Another Customer",
         "Incoming", "Sample Producer", "Sample Product Tax", "128.00"],
        ["Sales", "Sample Producer", "Included Producer Fee 2", "Sample Customer",
         "Incoming", "Sample Producer", "Sample Product Tax", "256.00"],
        ["Shipment", "Sample Distributor", "Sample Shipping Method", "Another Customer",
         nil, nil, "Platform Rate", "1.00"],
        ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
         nil, nil, "Platform Rate", "2.00"]
      ]

      expected_result.each_with_index do |expected_attributes, row_index|
        expect_total_attributes(totals.list[row_index], expected_attributes)
      end
    end
  end

  describe "filters entries correctly" do
    let(:parameters) { report_klass::Parameters.new(parameters_attributes) }
    let(:service) { described_class.new(parameters, nil) }

    context "filtering by completion date" do
      let(:timestamp) { Time.zone.local(2018, 1, 5, 14, 30, 5) }

      let!(:customer_a) { create(:customer, name: "Customer A") }
      let!(:customer_b) { create(:customer, name: "Customer B") }
      let!(:customer_c) { create(:customer, name: "Customer C") }

      let!(:order_placed_before_timestamp) do
        prepare_order(customer: customer_a).tap do |order|
          order.update_column(:completed_at, timestamp - 1.second)
        end
      end

      let!(:order_placed_during_timestamp) do
        prepare_order(customer: customer_b).tap do |order|
          order.update_column(:completed_at, timestamp)
        end
      end

      let!(:order_placed_after_timestamp) do
        prepare_order(customer: customer_c).tap do |order|
          order.update_column(:completed_at, timestamp + 1.second)
        end
      end

      context "on or after start_at" do
        let(:parameters_attributes) { { start_at: timestamp } }

        it "filters entries" do
          totals = service.enterprise_fee_type_totals.list

          expect_total_matches(totals, 0, fee_type: "Shipment", customer_name: "Customer A")
          expect_total_matches(totals, 1, fee_type: "Shipment", customer_name: "Customer B")
          expect_total_matches(totals, 1, fee_type: "Shipment", customer_name: "Customer C")
        end
      end

      context "on or before end_at" do
        let(:parameters_attributes) { { end_at: timestamp } }

        it "filters entries" do
          totals = service.enterprise_fee_type_totals.list

          expect_total_matches(totals, 1, fee_type: "Shipment", customer_name: "Customer A")
          expect_total_matches(totals, 1, fee_type: "Shipment", customer_name: "Customer B")
          expect_total_matches(totals, 0, fee_type: "Shipment", customer_name: "Customer C")
        end
      end
    end

    describe "for specified shops" do
      let!(:distributor_a) do
        create(:distributor_enterprise, name: "Distributor A", payment_methods: [payment_method],
                                        shipping_methods: [shipping_method])
      end
      let!(:distributor_b) do
        create(:distributor_enterprise, name: "Distributor B", payment_methods: [payment_method],
                                        shipping_methods: [shipping_method])
      end
      let!(:distributor_c) do
        create(:distributor_enterprise, name: "Distributor C", payment_methods: [payment_method],
                                        shipping_methods: [shipping_method])
      end

      let!(:order_a) { prepare_order(distributor: distributor_a) }
      let!(:order_b) { prepare_order(distributor: distributor_b) }
      let!(:order_c) { prepare_order(distributor: distributor_c) }

      let(:parameters_attributes) { { distributor_ids: [distributor_a.id, distributor_b.id] } }

      it "filters entries" do
        totals = service.enterprise_fee_type_totals.list

        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor A")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor B")
        expect_total_matches(totals, 0, fee_type: "Shipment", enterprise_name: "Distributor C")
      end
    end

    describe "for specified suppliers" do
      let!(:producer_a) { create(:supplier_enterprise, name: "Producer A") }
      let!(:producer_b) { create(:supplier_enterprise, name: "Producer B") }
      let!(:producer_c) { create(:supplier_enterprise, name: "Producer C") }

      let!(:fee_a) { create(:enterprise_fee, name: "Fee A", enterprise: producer_a) }
      let!(:fee_b) { create(:enterprise_fee, name: "Fee B", enterprise: producer_b) }
      let!(:fee_c) { create(:enterprise_fee, name: "Fee C", enterprise: producer_c) }

      let!(:product_a) { create(:product, supplier: producer_a) }
      let!(:product_b) { create(:product, supplier: producer_b) }
      let!(:product_c) { create(:product, supplier: producer_c) }

      let!(:variant_a) do
        prepare_variant(product: product_a, producer: producer_a, incoming_exchange_fees: [fee_a])
      end
      let!(:variant_b) do
        prepare_variant(product: product_b, producer: producer_b, incoming_exchange_fees: [fee_b])
      end
      let!(:variant_c) do
        prepare_variant(product: product_c, producer: producer_c, incoming_exchange_fees: [fee_c])
      end

      let!(:order_a) { prepare_order(variant: variant_a) }
      let!(:order_b) { prepare_order(variant: variant_b) }
      let!(:order_c) { prepare_order(variant: variant_c) }

      let(:parameters_attributes) { { producer_ids: [producer_a.id, producer_b.id] } }

      it "filters entries" do
        totals = service.enterprise_fee_type_totals.list

        expect_total_matches(totals, 1, fee_name: "Fee A", enterprise_name: "Producer A")
        expect_total_matches(totals, 1, fee_name: "Fee B", enterprise_name: "Producer B")
        expect_total_matches(totals, 0, fee_name: "Fee C", enterprise_name: "Producer C")
      end
    end

    describe "for specified order cycles" do
      let!(:distributor_a) do
        create(:distributor_enterprise, name: "Distributor A", payment_methods: [payment_method],
                                        shipping_methods: [shipping_method])
      end
      let!(:distributor_b) do
        create(:distributor_enterprise, name: "Distributor B", payment_methods: [payment_method],
                                        shipping_methods: [shipping_method])
      end
      let!(:distributor_c) do
        create(:distributor_enterprise, name: "Distributor C", payment_methods: [payment_method],
                                        shipping_methods: [shipping_method])
      end

      let!(:order_cycle_a) { create(:simple_order_cycle, coordinator: coordinator) }
      let!(:order_cycle_b) { create(:simple_order_cycle, coordinator: coordinator) }
      let!(:order_cycle_c) { create(:simple_order_cycle, coordinator: coordinator) }

      let!(:variant_a) { prepare_variant(distributor: distributor_a, order_cycle: order_cycle_a) }
      let!(:variant_b) { prepare_variant(distributor: distributor_b, order_cycle: order_cycle_b) }
      let!(:variant_c) { prepare_variant(distributor: distributor_c, order_cycle: order_cycle_c) }

      let!(:order_a) { prepare_order(order_cycle: order_cycle_a, distributor: distributor_a) }
      let!(:order_b) { prepare_order(order_cycle: order_cycle_b, distributor: distributor_b) }
      let!(:order_c) { prepare_order(order_cycle: order_cycle_c, distributor: distributor_c) }

      let(:parameters_attributes) { { order_cycle_ids: [order_cycle_a.id, order_cycle_b.id] } }

      it "filters entries" do
        totals = service.enterprise_fee_type_totals.list

        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor A")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor B")
        expect_total_matches(totals, 0, fee_type: "Shipment", enterprise_name: "Distributor C")
      end
    end

    describe "for specified enterprise fees" do
      let!(:fee_a) { create(:enterprise_fee, name: "Fee A", enterprise: distributor) }
      let!(:fee_b) { create(:enterprise_fee, name: "Fee B", enterprise: distributor) }
      let!(:fee_c) { create(:enterprise_fee, name: "Fee C", enterprise: distributor) }

      let!(:variant) { prepare_variant(outgoing_exchange_fees: [fee_a, fee_b, fee_c]) }

      let!(:order) { prepare_order(variant: variant) }

      let(:parameters_attributes) { { enterprise_fee_ids: [fee_a.id, fee_b.id] } }

      it "filters entries" do
        totals = service.enterprise_fee_type_totals.list

        expect_total_matches(totals, 1, fee_name: "Fee A")
        expect_total_matches(totals, 1, fee_name: "Fee B")
        expect_total_matches(totals, 0, fee_name: "Fee C")
      end
    end

    describe "for specified shipping methods" do
      let!(:shipping_method_a) do
        create(:shipping_method, name: "Shipping A", distributors: [distributor])
      end
      let!(:shipping_method_b) do
        create(:shipping_method, name: "Shipping B", distributors: [distributor])
      end
      let!(:shipping_method_c) do
        create(:shipping_method, name: "Shipping C", distributors: [distributor])
      end

      let!(:order_a) { prepare_order(shipping_method: shipping_method_a) }
      let!(:order_b) { prepare_order(shipping_method: shipping_method_b) }
      let!(:order_c) { prepare_order(shipping_method: shipping_method_c) }

      let(:parameters_attributes) do
        { shipping_method_ids: [shipping_method_a.id, shipping_method_b.id] }
      end

      it "filters entries" do
        totals = service.enterprise_fee_type_totals.list

        expect_total_matches(totals, 1, fee_name: "Shipping A")
        expect_total_matches(totals, 1, fee_name: "Shipping B")
        expect_total_matches(totals, 0, fee_name: "Shipping C")
      end
    end

    describe "for specified payment methods" do
      let!(:payment_method_a) do
        create(:payment_method, name: "Payment A", distributors: [distributor])
      end
      let!(:payment_method_b) do
        create(:payment_method, name: "Payment B", distributors: [distributor])
      end
      let!(:payment_method_c) do
        create(:payment_method, name: "Payment C", distributors: [distributor])
      end

      let!(:order_a) { prepare_order(payment_method: payment_method_a) }
      let!(:order_b) { prepare_order(payment_method: payment_method_b) }
      let!(:order_c) { prepare_order(payment_method: payment_method_c) }

      let(:parameters_attributes) do
        { payment_method_ids: [payment_method_a.id, payment_method_b.id] }
      end

      it "filters entries" do
        totals = service.enterprise_fee_type_totals.list

        expect_total_matches(totals, 1, fee_name: "Payment A")
        expect_total_matches(totals, 1, fee_name: "Payment B")
        expect_total_matches(totals, 0, fee_name: "Payment C")
      end
    end
  end

  # Helper methods for example group

  def expect_total_attributes(total, expected_attribute_list)
    actual_attribute_list = [total.fee_type, total.enterprise_name, total.fee_name,
                             total.customer_name, total.fee_placement,
                             total.fee_calculated_on_transfer_through_name, total.tax_category_name,
                             total.total_amount]
    expect(actual_attribute_list).to eq(expected_attribute_list)
  end

  def expect_total_matches(totals, count, attributes)
    expect(count_totals(totals, attributes)).to eq(count)
  end

  def prepare_tax_category(name)
    create(:tax_category, name: name)
  end

  def default_order_options
    { customer: customer, distributor: distributor, order_cycle: order_cycle,
      shipping_method: shipping_method, variant: variant }
  end

  def setup_order(options = {})
    target = default_order_options.merge(options)

    create(:order, customer: target[:customer], distributor: target[:distributor],
                   order_cycle: target[:order_cycle],
                   shipping_method: target[:shipping_method]).tap do |order|
      create(:line_item, order: order, variant: target[:variant])
      order.reload
    end
  end

  def prepare_order(options = {})
    order = setup_order(options)
    complete_order(order, options)
    order.reload
  end

  def complete_order(order, options)
    order.create_shipment!
    create(:payment, state: "checkout", order: order, amount: order.total,
                     payment_method: options[:payment_method] || payment_method)
    order.update_distribution_charge!
    while !order.completed? do break unless order.next! end
  end

  def default_variant_options
    { product: product, producer: producer, coordinator: coordinator, distributor: distributor,
      order_cycle: order_cycle }
  end

  def prepare_variant(options = {})
    target = default_variant_options.merge(options)

    create(:variant, product: target[:product], is_master: false).tap do |variant|
      exchange_options = { producer: target[:producer], coordinator: target[:coordinator],
                           distributor: target[:distributor],
                           incoming_exchange_fees: target[:incoming_exchange_fees],
                           outgoing_exchange_fees: target[:outgoing_exchange_fees] }
      setup_exchanges(target[:order_cycle], variant, exchange_options)
    end
  end

  def setup_exchanges(order_cycle, variant, options)
    setup_exchange(order_cycle, variant, true, sender: options[:producer],
                                               receiver: options[:coordinator],
                                               enterprise_fees: options[:incoming_exchange_fees])
    setup_exchange(order_cycle, variant, false, sender: options[:coordinator],
                                                receiver: options[:distributor],
                                                enterprise_fees: options[:outgoing_exchange_fees])
  end

  def setup_exchange(order_cycle, variant, incoming, options)
    exchange_attributes = { order_cycle_id: order_cycle.id, incoming: incoming,
                            sender_id: options[:sender].id, receiver_id: options[:receiver].id }
    exchange = Exchange.where(exchange_attributes).first || create(:exchange, exchange_attributes)
    exchange.variants << variant
    attach_enterprise_fees(exchange, options[:enterprise_fees] || [])
  end

  def attach_enterprise_fees(exchange, enterprise_fees)
    enterprise_fees.each do |enterprise_fee|
      exchange.enterprise_fees << enterprise_fee
    end
  end

  def per_item_calculator(amount)
    Spree::Calculator::PerItem.new(preferred_amount: amount)
  end

  def count_totals(totals, attributes)
    totals.count do |data|
      attributes.all? do |attribute_name, attribute_value|
        data.public_send(attribute_name) == attribute_value
      end
    end
  end
end
