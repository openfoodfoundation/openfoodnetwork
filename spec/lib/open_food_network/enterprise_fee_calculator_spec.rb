require 'open_food_network/enterprise_fee_calculator'

module OpenFoodNetwork
  describe EnterpriseFeeCalculator do
    describe "integration" do
      let(:coordinator) { create(:distributor_enterprise) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:product) { create(:simple_product, price: 10.00) }

      describe "calculating fees for a variant" do
        it "sums all the per-item fees for the variant in the specified hub + order cycle" do
          enterprise_fee1 = create(:enterprise_fee, amount: 20)
          enterprise_fee2 = create(:enterprise_fee, amount:  3)
          enterprise_fee3 = create(:enterprise_fee,
                                   calculator: Spree::Calculator::FlatRate.new(preferred_amount: 2))

          create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
                 enterprise_fees: [enterprise_fee1, enterprise_fee2, enterprise_fee3], variants: [product.master])

          EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product.master).should == 23
        end

        it "sums percentage fees for the variant" do
          enterprise_fee1 = create(:enterprise_fee, amount: 20, fee_type: "admin", calculator: Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 20))

          create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
                 enterprise_fees: [enterprise_fee1], variants: [product.master])

          product.master.price.should == 10.00
          EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product.master).should == 2.00
        end
      end

      describe "calculating fees by type" do
        let!(:ef_admin) { create(:enterprise_fee, fee_type: 'admin', amount: 1.23) }
        let!(:ef_sales) { create(:enterprise_fee, fee_type: 'sales', amount: 4.56) }
        let!(:ef_packing) { create(:enterprise_fee, fee_type: 'packing', amount: 7.89) }
        let!(:ef_transport) { create(:enterprise_fee, fee_type: 'transport', amount: 0.12) }
        let!(:exchange) { create(:exchange, order_cycle: order_cycle,
                                 sender: coordinator, receiver: distributor, incoming: false,
                                 enterprise_fees: [ef_admin, ef_sales, ef_packing, ef_transport],
                                 variants: [product.master]) }

        it "returns a breakdown of fees" do
          EnterpriseFeeCalculator.new(distributor, order_cycle).fees_by_type_for(product.master).should == {admin: 1.23, sales: 4.56, packing: 7.89, transport: 0.12}
        end
      end

      describe "creating adjustments" do
        let(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
        let!(:line_item) { create(:line_item, order: order, variant: product.master) }
        let(:enterprise_fee_line_item) { create(:enterprise_fee) }
        let(:enterprise_fee_order) { create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 2)) }
        let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false, variants: [product.master]) }

        before { order.reload }

        it "creates adjustments for a line item" do
          exchange.enterprise_fees << enterprise_fee_line_item

          EnterpriseFeeCalculator.new.create_line_item_adjustments_for line_item

          a = Spree::Adjustment.last
          a.metadata.fee_name.should == enterprise_fee_line_item.name
        end

        it "creates adjustments for an order" do
          exchange.enterprise_fees << enterprise_fee_order

          EnterpriseFeeCalculator.new.create_order_adjustments_for order

          a = Spree::Adjustment.last
          a.metadata.fee_name.should == enterprise_fee_order.name
        end
      end
    end

    describe "creating adjustments for a line item" do
      let(:oc) { OrderCycle.new }
      let(:variant) { double(:variant) }
      let(:distributor) { double(:distributor) }
      let(:order) { double(:order, distributor: distributor, order_cycle: oc) }
      let(:line_item) { double(:line_item, variant: variant, order: order) }

      it "creates an adjustment for each fee" do
        applicator = double(:enterprise_fee_applicator)
        applicator.should_receive(:create_line_item_adjustment).with(line_item)

        efc = EnterpriseFeeCalculator.new
        efc.should_receive(:per_item_enterprise_fee_applicators_for).with(variant) { [applicator] }

        efc.create_line_item_adjustments_for line_item
      end

      it "makes fee applicators for a line item" do
        distributor = double(:distributor)
        ef1 = double(:enterprise_fee)
        ef2 = double(:enterprise_fee)
        ef3 = double(:enterprise_fee)
        incoming_exchange = double(:exchange, role: 'supplier')
        outgoing_exchange = double(:exchange, role: 'distributor')
        incoming_exchange.stub_chain(:enterprise_fees, :per_item) { [ef1] }
        outgoing_exchange.stub_chain(:enterprise_fees, :per_item) { [ef2] }

        oc.stub(:exchanges_carrying) { [incoming_exchange, outgoing_exchange] }
        oc.stub_chain(:coordinator_fees, :per_item) { [ef3] }

        efc = EnterpriseFeeCalculator.new(distributor, oc)
        efc.send(:per_item_enterprise_fee_applicators_for, line_item.variant).should ==
          [OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, line_item.variant, 'supplier'),
           OpenFoodNetwork::EnterpriseFeeApplicator.new(ef2, line_item.variant, 'distributor'),
           OpenFoodNetwork::EnterpriseFeeApplicator.new(ef3, line_item.variant, 'coordinator')]
      end
    end

    describe "creating adjustments for an order" do
      let(:oc) { OrderCycle.new }
      let(:distributor) { double(:distributor) }
      let(:order) { double(:order, distributor: distributor, order_cycle: oc) }

      it "creates an adjustment for each fee" do
        applicator = double(:enterprise_fee_applicator)
        applicator.should_receive(:create_order_adjustment).with(order)

        efc = EnterpriseFeeCalculator.new
        efc.should_receive(:per_order_enterprise_fee_applicators_for).with(order) { [applicator] }

        efc.create_order_adjustments_for order
      end

      it "makes fee applicators for an order" do
        distributor = double(:distributor)
        ef1 = double(:enterprise_fee)
        ef2 = double(:enterprise_fee)
        ef3 = double(:enterprise_fee)
        incoming_exchange = double(:exchange, role: 'supplier')
        outgoing_exchange = double(:exchange, role: 'distributor')
        incoming_exchange.stub_chain(:enterprise_fees, :per_order) { [ef1] }
        outgoing_exchange.stub_chain(:enterprise_fees, :per_order) { [ef2] }

        oc.stub(:exchanges_supplying) { [incoming_exchange, outgoing_exchange] }
        oc.stub_chain(:coordinator_fees, :per_order) { [ef3] }

        efc = EnterpriseFeeCalculator.new(distributor, oc)
        efc.send(:per_order_enterprise_fee_applicators_for, order).should ==
          [OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, nil, 'supplier'),
           OpenFoodNetwork::EnterpriseFeeApplicator.new(ef2, nil, 'distributor'),
           OpenFoodNetwork::EnterpriseFeeApplicator.new(ef3, nil, 'coordinator')]
      end
    end
  end
end
