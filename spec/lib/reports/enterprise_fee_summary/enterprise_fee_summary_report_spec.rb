# frozen_string_literal: true

require "spec_helper"

describe Reporting::Reports::EnterpriseFeeSummary::Base do
  let(:report_module) { Reporting::Reports::EnterpriseFeeSummary }

  # Basic data.
  let!(:shipping_method) do
    create(:shipping_method, :per_item, amount: 1, name: "Sample Shipping Method")
  end

  let!(:payment_method) do
    create(:payment_method, :per_item, amount: 2, name: "Sample Payment Method")
  end

  # Create enterprises.
  let!(:distributor) do
    create(:distributor_enterprise, name: "Sample Distributor").tap do |enterprise|
      payment_method.distributors << enterprise
      shipping_method.distributors << enterprise
    end
  end
  let!(:producer) { create(:supplier_enterprise, name: "Sample Producer") }
  let!(:coordinator) { create(:enterprise, name: "Sample Coordinator") }

  # Add some fee noise.
  let!(:other_distributor_fee) { create(:enterprise_fee, :per_item, enterprise: distributor) }
  let!(:other_producer_fee) { create(:enterprise_fee, :per_item, enterprise: producer) }
  let!(:other_coordinator_fee) { create(:enterprise_fee, :per_item, enterprise: coordinator) }

  # Set up other requirements for ordering.
  let!(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
  let!(:product) { create(:product, tax_category: product_tax_category) }
  let!(:product_tax_category) { create(:tax_category, name: "Sample Product Tax") }
  let!(:variant) { prepare_variant }

  # Create customers.
  let!(:customer) { create(:customer, first_name: "Sample", last_name: "Customer") }
  let!(:another_customer) { create(:customer, first_name: "Another", last_name: "Customer") }

  # Setup up permissions and report.
  let!(:current_user) { create(:admin_user) }
  let(:parameters) { report_module::Parameters.new }
  let(:subject) {
    report = described_class.new(current_user)
    allow(report).to receive(:parameters).and_return(parameters)
    report
  }

  describe "grouping and sorting of entries" do
    let!(:order_cycle) do
      create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: order_cycle_fees)
    end

    let!(:variant) do
      prepare_variant(incoming_exchange_fees: variant_incoming_exchange_fees,
                      outgoing_exchange_fees: variant_outgoing_exchange_fees)
    end

    let!(:order_cycle_fees) do
      [
        create(:enterprise_fee, :per_item, name: "Coordinator Fee 1", enterprise: coordinator,
                                           fee_type: "admin", amount: 512.0,
                                           tax_category: coordinator_tax_category),
        create(:enterprise_fee, :per_item, name: "Coordinator Fee 2", enterprise: coordinator,
                                           fee_type: "sales", amount: 1024.0,
                                           inherits_tax_category: true)
      ]
    end
    let!(:coordinator_tax_category) { create(:tax_category, name: "Sample Coordinator Tax") }

    let!(:variant_incoming_exchange_fees) do
      [
        create(:enterprise_fee, :per_item, name: "Producer Fee 1", enterprise: producer,
                                           fee_type: "sales", amount: 64.0,
                                           tax_category: producer_tax_category),
        create(:enterprise_fee, :per_item, name: "Producer Fee 2", enterprise: producer,
                                           fee_type: "sales", amount: 128.0,
                                           inherits_tax_category: true)
      ]
    end
    let!(:producer_tax_category) { create(:tax_category, name: "Sample Producer Tax") }

    let!(:variant_outgoing_exchange_fees) do
      [
        create(:enterprise_fee, :per_item, name: "Distributor Fee 1", enterprise: distributor,
                                           fee_type: "admin", amount: 4.0,
                                           tax_category: distributor_tax_category),
        create(:enterprise_fee, :per_item, name: "Distributor Fee 2", enterprise: distributor,
                                           fee_type: "sales", amount: 8.0,
                                           inherits_tax_category: true)
      ]
    end
    let!(:distributor_tax_category) { create(:tax_category, name: "Sample Distributor Tax") }

    let!(:customer_order) { prepare_order(customer: customer) }
    let!(:customer_incomplete_order) { prepare_incomplete_order(customer: customer) }
    let!(:second_customer_order) { prepare_order(customer: customer) }
    let!(:other_customer_order) { prepare_order(customer: another_customer) }

    it "doesn't delete params" do
      params = ActionController::Parameters.new("completed_at_gt" => "2023-02-08+00:00")
      described_class.new(current_user, params)
      expect(params["completed_at_gt"]).to eq "2023-02-08+00:00"
    end

    it "groups and sorts entries correctly" do
      totals = subject.query_result

      expect(totals.length).to eq(16)

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
        ["Admin", "Sample Coordinator", "Coordinator Fee 1", "Another Customer",
         "Coordinator", "All", "Sample Coordinator Tax", 512],
        ["Admin", "Sample Coordinator", "Coordinator Fee 1", "Sample Customer",
         "Coordinator", "All", "Sample Coordinator Tax", 1024],
        ["Admin", "Sample Distributor", "Distributor Fee 1", "Another Customer",
         "Outgoing", "Sample Distributor", "Sample Distributor Tax", 4],
        ["Admin", "Sample Distributor", "Distributor Fee 1", "Sample Customer",
         "Outgoing", "Sample Distributor", "Sample Distributor Tax", 8],
        ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Another Customer",
         nil, nil, nil, 2],
        ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Sample Customer",
         nil, nil, nil, 4],
        ["Sales", "Sample Coordinator", "Coordinator Fee 2", "Another Customer",
         "Coordinator", "All", "Various", 1024],
        ["Sales", "Sample Coordinator", "Coordinator Fee 2", "Sample Customer",
         "Coordinator", "All", "Various", 2048],
        ["Sales", "Sample Distributor", "Distributor Fee 2", "Another Customer",
         "Outgoing", "Sample Distributor", "Sample Product Tax", 8],
        ["Sales", "Sample Distributor", "Distributor Fee 2", "Sample Customer",
         "Outgoing", "Sample Distributor", "Sample Product Tax", 16],
        ["Sales", "Sample Producer", "Producer Fee 1", "Another Customer",
         "Incoming", "Sample Producer", "Sample Producer Tax", 64],
        ["Sales", "Sample Producer", "Producer Fee 1", "Sample Customer",
         "Incoming", "Sample Producer", "Sample Producer Tax", 128],
        ["Sales", "Sample Producer", "Producer Fee 2", "Another Customer",
         "Incoming", "Sample Producer", "Sample Product Tax", 128],
        ["Sales", "Sample Producer", "Producer Fee 2", "Sample Customer",
         "Incoming", "Sample Producer", "Sample Product Tax", 256],
        ["Shipment", "Sample Distributor", "Sample Shipping Method", "Another Customer",
         nil, nil, "Platform Rate", 1],
        ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
         nil, nil, "Platform Rate", 2]
      ]

      expected_result.each_with_index do |expected_attributes, row_index|
        expect_total_attributes(totals[row_index], expected_attributes)
      end
    end
  end

  describe "data exclusions" do
    describe "invalid adjustments (through 'eligible') like failed payments" do
      let!(:customer_order) { prepare_order(customer: customer) }

      before do
        # Make the payment fail. See Spree::Payment#revoke_adjustment_eligibility.
        payment = customer_order.payments.first
        payment.state = "failed"
        payment.save!
      end

      it "is included" do
        totals = subject.query_result

        expect(totals.length).to eq(1)

        expected_result = [
          ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
           nil, nil, "Platform Rate", 1]
        ]

        expected_result.each_with_index do |expected_attributes, row_index|
          expect_total_attributes(totals[row_index], expected_attributes)
        end
      end
    end

    describe "non-mandatory $0 adjustments (through 'eligible')" do
      let!(:variant) { prepare_variant(outgoing_exchange_fees: [enterprise_fee]) }

      let!(:enterprise_fee) do
        create(:enterprise_fee, :per_item, name: "Sample Enterprise Fee", enterprise: distributor,
                                           fee_type: "admin", amount: 0)
      end

      let!(:customer_order) { prepare_order(customer: customer) }

      before do
        # Change "eligible" in enterprise fee adjustment to false. $0 adjustments that are not
        # mandatory are set to be ineligible, but there are no non-mandatory adjustments supported
        # by the report yet.
        adjustment = Spree::Adjustment.where(originator_type: "EnterpriseFee").first
        adjustment.eligible = false
        adjustment.save!
      end

      it "is included" do
        totals = subject.query_result

        expect(totals.length).to eq(2)

        expected_result = [
          ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Sample Customer",
           nil, nil, nil, 2],
          ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
           nil, nil, "Platform Rate", 1]
        ]

        expected_result.each_with_index do |expected_attributes, row_index|
          expect_total_attributes(totals[row_index], expected_attributes)
        end
      end
    end

    describe "$0 mandatory adjustments" do
      let!(:payment_method) do
        create(:payment_method, :per_item, amount: 0, name: "Sample Payment Method")
      end

      let!(:customer_order) { prepare_order(customer: customer) }

      it "is included" do
        totals = subject.query_result

        expect(totals.length).to eq(1)

        expected_result = [
          ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
           nil, nil, "Platform Rate", 1]
        ]

        expected_result.each_with_index do |expected_attributes, row_index|
          expect_total_attributes(totals[row_index], expected_attributes)
        end
      end
    end
  end

  describe "handling of more complex cases" do
    context "with non-sender fee for incoming exchange and non-receiver fee for outgoing" do
      let!(:variant) do
        prepare_variant(incoming_exchange_fees: variant_incoming_exchange_fees,
                        outgoing_exchange_fees: variant_outgoing_exchange_fees)
      end
      let!(:variant_incoming_exchange_fees) { [coordinator_fee, distributor_fee] }
      let!(:variant_outgoing_exchange_fees) { [producer_fee, coordinator_fee] }

      let!(:producer_fee) do
        tax_category = create(:tax_category, name: "Sample Producer Tax")
        create(:enterprise_fee, :per_item, name: "Sample Producer Fee", enterprise: producer,
                                           fee_type: "sales", amount: 64.0,
                                           tax_category: tax_category)
      end
      let!(:coordinator_fee) do
        tax_category = create(:tax_category, name: "Sample Coordinator Tax")
        create(:enterprise_fee, :per_item, name: "Sample Coordinator Fee", enterprise: coordinator,
                                           fee_type: "admin", amount: 512.0,
                                           tax_category: tax_category)
      end
      let!(:distributor_fee) do
        tax_category = create(:tax_category, name: "Sample Distributor Tax")
        create(:enterprise_fee, :per_item, name: "Sample Distributor Fee", enterprise: distributor,
                                           fee_type: "admin", amount: 4.0,
                                           tax_category: tax_category)
      end

      let!(:customer_order) { prepare_order(customer: customer) }

      it "fetches data correctly" do
        totals = subject.query_result

        expect(totals.length).to eq(6)

        expected_result = [
          ["Admin", "Sample Coordinator", "Sample Coordinator Fee", "Sample Customer",
           "Incoming", "Sample Producer", "Sample Coordinator Tax", 512],
          ["Admin", "Sample Coordinator", "Sample Coordinator Fee", "Sample Customer",
           "Outgoing", "Sample Distributor", "Sample Coordinator Tax", 512],
          ["Admin", "Sample Distributor", "Sample Distributor Fee", "Sample Customer",
           "Incoming", "Sample Producer", "Sample Distributor Tax", 4],
          ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Sample Customer",
           nil, nil, nil, 2],
          ["Sales", "Sample Producer", "Sample Producer Fee", "Sample Customer",
           "Outgoing", "Sample Distributor", "Sample Producer Tax", 64],
          ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
           nil, nil, "Platform Rate", 1]
        ]

        expected_result.each_with_index do |expected_attributes, row_index|
          expect_total_attributes(totals[row_index], expected_attributes)
        end
      end
    end

    context "with order-based enterprise fee calculator" do
      let!(:producer_fee) do
        tax_category = create(:tax_category, name: "Producer Tax A")
        create(:enterprise_fee, :flat_rate, name: "Producer Fee A", enterprise: producer,
                                            fee_type: "sales", tax_category: tax_category,
                                            amount: 10)
      end
      let!(:coordinator_fee) do
        tax_category = create(:tax_category, name: "Coordinator Tax A")
        create(:enterprise_fee, :flat_rate, name: "Coordinator Fee A", enterprise: coordinator,
                                            fee_type: "admin", tax_category: tax_category,
                                            amount: 15)
      end
      let!(:coordinator_fee_inheriting_product_tax_category) do
        create(:enterprise_fee, :flat_rate, name: "Coordinator Fee B", enterprise: coordinator,
                                            fee_type: "admin", inherits_tax_category: true,
                                            amount: 20)
      end
      let!(:coordinator_fee_without_tax) do
        create(:enterprise_fee, :flat_rate, name: "Coordinator Fee C", enterprise: coordinator,
                                            fee_type: "admin", inherits_tax_category: false,
                                            amount: 25)
      end
      let!(:distributor_fee) do
        create(:enterprise_fee, :flat_rate, name: "Distributor Fee A", enterprise: distributor,
                                            fee_type: "admin", inherits_tax_category: false,
                                            amount: 30)
      end

      let!(:coordinator_fees) do
        [
          coordinator_fee,
          coordinator_fee_inheriting_product_tax_category,
          coordinator_fee_without_tax
        ]
      end

      let!(:order_cycle) do
        create(:simple_order_cycle, coordinator: coordinator, coordinator_fees: coordinator_fees)
      end

      let!(:variant_incoming_exchange_fees) { [producer_fee, coordinator_fee, distributor_fee] }
      let!(:variant_outgoing_exchange_fees) { [producer_fee, coordinator_fee, distributor_fee] }

      let!(:variant) do
        prepare_variant(incoming_exchange_fees: variant_incoming_exchange_fees,
                        outgoing_exchange_fees: variant_outgoing_exchange_fees)
      end

      let!(:customer_order) { prepare_order(customer: customer) }

      it "fetches data correctly" do
        totals = subject.query_result

        expect(totals.length).to eq(11)

        entire_orders_text = i18n_translate("fee_calculated_on_transfer_through_entire_orders",
                                            distributor: "Sample Distributor")
        various_tax_categories_text = i18n_translate("tax_category_various")

        expected_result = [
          ["Admin", "Sample Coordinator", "Coordinator Fee A", "Sample Customer",
           "Coordinator", "All", "Coordinator Tax A", 15],
          ["Admin", "Sample Coordinator", "Coordinator Fee A", "Sample Customer",
           "Incoming", entire_orders_text, "Coordinator Tax A", 15],
          ["Admin", "Sample Coordinator", "Coordinator Fee A", "Sample Customer",
           "Outgoing", entire_orders_text, "Coordinator Tax A", 15],
          ["Admin", "Sample Coordinator", "Coordinator Fee B", "Sample Customer",
           "Coordinator", "All", various_tax_categories_text, 20],
          ["Admin", "Sample Coordinator", "Coordinator Fee C", "Sample Customer",
           "Coordinator", "All", nil, 25],
          ["Admin", "Sample Distributor", "Distributor Fee A", "Sample Customer",
           "Incoming", entire_orders_text, various_tax_categories_text, 30],
          ["Admin", "Sample Distributor", "Distributor Fee A", "Sample Customer",
           "Outgoing", entire_orders_text, various_tax_categories_text, 30],
          ["Payment Transaction", "Sample Distributor", "Sample Payment Method", "Sample Customer",
           nil, nil, nil, 2],
          ["Sales", "Sample Producer", "Producer Fee A", "Sample Customer",
           "Incoming", entire_orders_text, "Producer Tax A", 10],
          ["Sales", "Sample Producer", "Producer Fee A", "Sample Customer",
           "Outgoing", entire_orders_text, "Producer Tax A", 10],
          ["Shipment", "Sample Distributor", "Sample Shipping Method", "Sample Customer",
           nil, nil, "Platform Rate", 1]
        ]

        expected_result.each_with_index do |expected_attributes, row_index|
          expect_total_attributes(totals[row_index], expected_attributes)
        end
      end
    end
  end

  describe "filtering results based on permissions" do
    let!(:distributor_a) do
      create(:distributor_enterprise, name: "Distributor A", payment_methods: [payment_method],
                                      shipping_methods: [shipping_method])
    end
    let!(:distributor_b) do
      create(:distributor_enterprise, name: "Distributor B", payment_methods: [payment_method],
                                      shipping_methods: [shipping_method])
    end

    let!(:order_cycle_a) { create(:simple_order_cycle, coordinator: coordinator) }
    let!(:order_cycle_b) { create(:simple_order_cycle, coordinator: coordinator) }

    let!(:variant_a) { prepare_variant(distributor: distributor_a, order_cycle: order_cycle_a) }
    let!(:variant_b) { prepare_variant(distributor: distributor_b, order_cycle: order_cycle_b) }

    let!(:order_a) { prepare_order(order_cycle: order_cycle_a, distributor: distributor_a) }
    let!(:order_b) { prepare_order(order_cycle: order_cycle_b, distributor: distributor_b) }

    context "when admin" do
      let!(:current_user) { create(:admin_user) }

      it "includes all order cycles" do
        totals = subject.query_result

        expect_total_matches(totals, 2, fee_type: "Shipment")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor A")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor B")
      end
    end

    context "when enterprise owner for distributor" do
      let!(:current_user) { distributor_a.owner }

      it "does not include unrelated order cycles" do
        totals = subject.query_result

        expect_total_matches(totals, 1, fee_type: "Shipment")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor A")
      end
    end
  end

  describe "filters entries correctly" do
    let(:parameters) { report_module::Parameters.new(parameters_attributes) }

    context "filtering by completion date" do
      let(:timestamp) { Time.zone.local(2018, 1, 5, 14, 30, 5) }

      let!(:customer_a) { create(:customer, first_name: "Customer", last_name: "A") }
      let!(:customer_b) { create(:customer, first_name: "Customer", last_name: "B") }
      let!(:customer_c) { create(:customer, first_name: "Customer", last_name: "C") }

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

      context "on or after completed_at_gt" do
        let(:parameters_attributes) { { completed_at_gt: timestamp } }

        it "filters entries" do
          totals = subject.query_result

          expect_total_matches(totals, 0, fee_type: "Shipment", customer_name: "Customer A")
          expect_total_matches(totals, 1, fee_type: "Shipment", customer_name: "Customer B")
          expect_total_matches(totals, 1, fee_type: "Shipment", customer_name: "Customer C")
        end
      end

      context "on or before completed_at_lt" do
        let(:parameters_attributes) { { completed_at_lt: timestamp } }

        it "filters entries" do
          totals = subject.query_result

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
        totals = subject.query_result

        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor A")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor B")
        expect_total_matches(totals, 0, fee_type: "Shipment", enterprise_name: "Distributor C")
      end
    end

    describe "for specified suppliers" do
      let!(:producer_a) { create(:supplier_enterprise, name: "Producer A") }
      let!(:producer_b) { create(:supplier_enterprise, name: "Producer B") }
      let!(:producer_c) { create(:supplier_enterprise, name: "Producer C") }

      let!(:fee_a) { create(:enterprise_fee, name: "Fee A", enterprise: producer_a, amount: 1) }
      let!(:fee_b) { create(:enterprise_fee, name: "Fee B", enterprise: producer_b, amount: 1) }
      let!(:fee_c) { create(:enterprise_fee, name: "Fee C", enterprise: producer_c, amount: 1) }

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
        totals = subject.query_result

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
        totals = subject.query_result

        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor A")
        expect_total_matches(totals, 1, fee_type: "Shipment", enterprise_name: "Distributor B")
        expect_total_matches(totals, 0, fee_type: "Shipment", enterprise_name: "Distributor C")
      end
    end

    describe "for specified enterprise fees" do
      let!(:fee_a) { create(:enterprise_fee, name: "Fee A", enterprise: distributor, amount: 1) }
      let!(:fee_b) { create(:enterprise_fee, name: "Fee B", enterprise: distributor, amount: 1) }
      let!(:fee_c) { create(:enterprise_fee, name: "Fee C", enterprise: distributor, amount: 1) }

      let!(:variant) { prepare_variant(outgoing_exchange_fees: variant_outgoing_exchange_fees) }
      let!(:variant_outgoing_exchange_fees) { [fee_a, fee_b, fee_c] }

      let!(:order) { prepare_order(variant: variant) }

      let(:parameters_attributes) { { enterprise_fee_ids: [fee_a.id, fee_b.id] } }

      it "filters entries" do
        totals = subject.query_result

        expect_total_matches(totals, 1, fee_name: "Fee A")
        expect_total_matches(totals, 1, fee_name: "Fee B")
        expect_total_matches(totals, 0, fee_name: "Fee C")
      end
    end

    describe "for specified shipping methods" do
      let!(:shipping_method_a) do
        method = create(:shipping_method, name: "Shipping A", distributors: [distributor])
        method.calculator.update_attribute(:preferred_amount, 1)
        method
      end
      let!(:shipping_method_b) do
        method = create(:shipping_method, name: "Shipping B", distributors: [distributor])
        method.calculator.update_attribute(:preferred_amount, 1)
        method
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
        totals = subject.query_result

        expect_total_matches(totals, 1, fee_name: "Shipping A")
        expect_total_matches(totals, 1, fee_name: "Shipping B")
        expect_total_matches(totals, 0, fee_name: "Shipping C")
      end
    end

    describe "for specified payment methods" do
      let!(:payment_method_a) do
        method = create(:payment_method, :flat_rate, name: "Payment A", distributors: [distributor])
        method.calculator.update_attribute(:preferred_amount, 1)
        method
      end
      let!(:payment_method_b) do
        method = create(:payment_method, :flat_rate, name: "Payment B", distributors: [distributor])
        method.calculator.update_attribute(:preferred_amount, 1)
        method
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
        totals = subject.query_result

        expect_total_matches(totals, 1, fee_name: "Payment A")
        expect_total_matches(totals, 1, fee_name: "Payment B")
        expect_total_matches(totals, 0, fee_name: "Payment C")
      end
    end
  end

  # Helper methods for example group

  def i18n_translate(translation_key, options = {})
    I18n.t("order_management.reports.enterprise_fee_summary.#{translation_key}", **options)
  end

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

  def default_order_options
    { customer: customer, distributor: distributor, order_cycle: order_cycle,
      shipping_method: shipping_method, variant: variant }
  end

  def prepare_incomplete_order(options = {})
    target_options = default_order_options.merge(options)
    create(:order, :with_line_item, target_options)
  end

  def prepare_order(options = {})
    factory_trait_options = { payment_method: payment_method }
    target_options = default_order_options.merge(factory_trait_options).merge(options)
    create(:order, :with_line_item, :completed, target_options)
  end

  def default_variant_options
    { product: product, producer: producer, is_master: false, coordinator: coordinator,
      distributor: distributor, order_cycle: order_cycle }
  end

  def prepare_variant(options = {})
    target_options = default_variant_options.merge(options)
    create(:variant, :with_order_cycle, target_options)
  end

  def count_totals(totals, attributes)
    totals.count do |data|
      attributes.all? do |attribute_name, attribute_value|
        data.public_send(attribute_name) == attribute_value
      end
    end
  end
end
