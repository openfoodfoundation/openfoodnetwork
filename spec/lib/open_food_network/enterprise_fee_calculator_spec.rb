require 'open_food_network/enterprise_fee_calculator'

module OpenFoodNetwork
  describe EnterpriseFeeCalculator do
    describe "integration" do
      let(:supplier1)    { create(:supplier_enterprise) }
      let(:supplier2)    { create(:supplier_enterprise) }
      let(:coordinator) { create(:distributor_enterprise) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle) }
      let(:product1) { create(:simple_product, supplier: supplier1, price: 10.00) }
      let(:product2) { create(:simple_product, supplier: supplier2, price: 20.00) }

      describe "calculating fees for a variant" do
        describe "summing all the per-item fees for the variant in the specified hub + order cycle" do
          let(:enterprise_fee1) { create(:enterprise_fee, amount: 20) }
          let(:enterprise_fee2) { create(:enterprise_fee, amount:  3) }
          let(:enterprise_fee3) { create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 2)) }

          describe "supplier fees" do
            let!(:exchange1) { create(:exchange, order_cycle: order_cycle, sender: supplier1, receiver: coordinator, incoming: true,
                                     enterprise_fees: [enterprise_fee1], variants: [product1.master]) }
            let!(:exchange2) { create(:exchange, order_cycle: order_cycle, sender: supplier2, receiver: coordinator, incoming: true,
                                     enterprise_fees: [enterprise_fee2], variants: [product2.master]) }

            it "calculates via regular computation" do
              EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product1.master).should == 20
              EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product2.master).should == 3
           end

            it "calculates via indexed computation" do
              EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_for(product1.master).should == 20
              EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_for(product2.master).should == 3
            end
          end

          describe "coordinator fees" do
            let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
                                     enterprise_fees: [], variants: [product1.master]) }

            before do
              order_cycle.coordinator_fees = [enterprise_fee1, enterprise_fee2, enterprise_fee3]
            end

            it "sums via regular computation" do
              EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product1.master).should == 23
            end

            it "sums via indexed computation" do
              EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_for(product1.master).should == 23
            end
          end

          describe "distributor fees" do
            let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
                                     enterprise_fees: [enterprise_fee1, enterprise_fee2, enterprise_fee3], variants: [product1.master]) }

            it "sums via regular computation" do
              EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product1.master).should == 23
            end

            it "sums via indexed computation" do
              EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_for(product1.master).should == 23
            end
          end
        end

        describe "summing percentage fees for the variant" do
          let!(:enterprise_fee1) { create(:enterprise_fee, amount: 20, fee_type: "admin", calculator: Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 20)) }
          let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false,
                                   enterprise_fees: [enterprise_fee1], variants: [product1.master]) }

          it "sums via regular computation" do
            EnterpriseFeeCalculator.new(distributor, order_cycle).fees_for(product1.master).should == 2.00
          end

          it "sums via indexed computation" do
            EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_for(product1.master).should == 2.00
          end
        end
      end

      describe "calculating fees by type" do
        let!(:ef_admin) { create(:enterprise_fee, fee_type: 'admin', amount: 1.23) }
        let!(:ef_sales) { create(:enterprise_fee, fee_type: 'sales', amount: 4.56) }
        let!(:ef_packing) { create(:enterprise_fee, fee_type: 'packing', amount: 7.89) }
        let!(:ef_transport) { create(:enterprise_fee, fee_type: 'transport', amount: 0.12) }
        let!(:ef_fundraising) { create(:enterprise_fee, fee_type: 'fundraising', amount: 3.45) }
        let!(:exchange) { create(:exchange, order_cycle: order_cycle,
                                 sender: coordinator, receiver: distributor, incoming: false,
                                 enterprise_fees: [ef_admin, ef_sales, ef_packing, ef_transport, ef_fundraising],
                                 variants: [product1.master]) }

        describe "regular computation" do
          it "returns a breakdown of fees" do
            EnterpriseFeeCalculator.new(distributor, order_cycle).fees_by_type_for(product1.master).should == {admin: 1.23, sales: 4.56, packing: 7.89, transport: 0.12, fundraising: 3.45}
          end

          it "filters out zero fees" do
            ef_admin.calculator.update_attribute :preferred_amount, 0
            EnterpriseFeeCalculator.new(distributor, order_cycle).fees_by_type_for(product1.master).should == {sales: 4.56, packing: 7.89, transport: 0.12, fundraising: 3.45}
          end
        end

        describe "indexed computation" do
          it "returns a breakdown of fees" do
            EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_by_type_for(product1.master).should == {admin: 1.23, sales: 4.56, packing: 7.89, transport: 0.12, fundraising: 3.45}
          end

          it "filters out zero fees" do
            ef_admin.calculator.update_attribute :preferred_amount, 0
            EnterpriseFeeCalculator.new(distributor, order_cycle).indexed_fees_by_type_for(product1.master).should == {sales: 4.56, packing: 7.89, transport: 0.12, fundraising: 3.45}
          end
        end
      end

      describe "creating adjustments" do
        let(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
        let!(:line_item) { create(:line_item, order: order, variant: product1.master) }
        let(:enterprise_fee_line_item) { create(:enterprise_fee) }
        let(:enterprise_fee_order) { create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new(preferred_amount: 2)) }
        let!(:exchange) { create(:exchange, order_cycle: order_cycle, sender: coordinator, receiver: distributor, incoming: false, variants: [product1.master]) }

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


    describe "indexed fee retrieval" do
      subject { EnterpriseFeeCalculator.new distributor, order_cycle }
      let(:order_cycle) { create(:simple_order_cycle, coordinator_fees: [ef_coordinator]) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:distributor_other) { create(:distributor_enterprise) }
      let!(:ef_absent) { create(:enterprise_fee) }
      let!(:ef_exchange) { create(:enterprise_fee) }
      let!(:ef_coordinator) { create(:enterprise_fee) }
      let!(:ef_other_distributor) { create(:enterprise_fee) }
      let!(:exchange) { create(:exchange, sender: order_cycle.coordinator, receiver: distributor, order_cycle: order_cycle, enterprise_fees: [ef_exchange], variants: [v]) }
      let(:v) { create(:variant) }
      let(:indexed_variants) { {v.id => v} }
      let(:indexed_enterprise_fees) { subject.instance_variable_get(:@indexed_enterprise_fees) }

      before { subject.instance_variable_set(:@indexed_enterprise_fees, {}) }

      describe "fetching enterprise fees with pre-loaded exchange details" do
        it "scopes enterprise fees to those on exchanges for the current order cycle" do
          subject.send(:per_item_enterprise_fees_with_exchange_details).should == [ef_exchange]
        end

        it "includes the exchange variant id" do
          subject.send(:per_item_enterprise_fees_with_exchange_details).first.variant_id.to_i.should ==
            v.id
        end

        it "does not include outgoing exchanges to other distributors" do
          create(:exchange, order_cycle: order_cycle, sender: order_cycle.coordinator, receiver: distributor_other, enterprise_fees: [ef_other_distributor], variants: [v])

          subject.send(:per_item_enterprise_fees_with_exchange_details).should == [ef_exchange]
        end
      end

      describe "loading exchange fees" do
        let(:exchange_fees) { subject.send(:per_item_enterprise_fees_with_exchange_details) }

        it "loads exchange fees" do
          subject.send(:load_exchange_fees, exchange_fees)
          indexed_enterprise_fees.should == {v.id => [ef_exchange]}
        end
      end

      describe "loading coordinator fees" do
        it "loads coordinator fees" do
          subject.send(:load_coordinator_fees)
          indexed_enterprise_fees.should == {v.id => [ef_coordinator]}
        end
      end
    end

    describe "creating adjustments" do
      let(:oc) { OrderCycle.new }
      let(:distributor) { double(:distributor) }
      let(:ef1) { double(:enterprise_fee) }
      let(:ef2) { double(:enterprise_fee) }
      let(:ef3) { double(:enterprise_fee) }
      let(:incoming_exchange) { double(:exchange, role: 'supplier') }
      let(:outgoing_exchange) { double(:exchange, role: 'distributor') }
      let(:applicator) { double(:enterprise_fee_applicator) }


      describe "for a line item" do
        let(:variant) { double(:variant) }
        let(:line_item) { double(:line_item, variant: variant, order: order) }

        before do
          allow(incoming_exchange).to receive(:enterprise_fees) { double(:enterprise_fees, per_item: [ef1]) }
          allow(outgoing_exchange).to receive(:enterprise_fees) { double(:enterprise_fees, per_item: [ef2]) }
          allow(oc).to receive(:exchanges_carrying) { [incoming_exchange, outgoing_exchange] }
          allow(oc).to receive(:coordinator_fees) { double(:coodinator_fees, per_item: [ef3]) }
        end

        context "with order_cycle and distributor set" do
          let(:efc) { EnterpriseFeeCalculator.new(distributor, oc) }
          let(:order) { double(:order, distributor: distributor, order_cycle: oc) }

          it "creates an adjustment for each fee" do
            expect(efc).to receive(:per_item_enterprise_fee_applicators_for).with(variant) { [applicator] }
            expect(applicator).to receive(:create_line_item_adjustment).with(line_item)
            efc.create_line_item_adjustments_for line_item
          end

          it "makes fee applicators for a line item" do
            expect(efc.send(:per_item_enterprise_fee_applicators_for, line_item.variant))
            .to eq [OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, line_item.variant, 'supplier'),
                    OpenFoodNetwork::EnterpriseFeeApplicator.new(ef2, line_item.variant, 'distributor'),
                    OpenFoodNetwork::EnterpriseFeeApplicator.new(ef3, line_item.variant, 'coordinator')]
          end
        end

        context "with no order_cycle or distributor set" do
          let(:efc) { EnterpriseFeeCalculator.new }
          let(:order) { double(:order, distributor: nil, order_cycle: nil) }

          it "does not make applicators for an order" do
            expect(efc.send(:per_item_enterprise_fee_applicators_for, line_item.variant)).to eq []
          end
        end
      end

      describe "for an order" do
        before do
          allow(incoming_exchange).to receive(:enterprise_fees) { double(:enterprise_fees, per_order: [ef1]) }
          allow(outgoing_exchange).to receive(:enterprise_fees) { double(:enterprise_fees, per_order: [ef2]) }
          allow(oc).to receive(:exchanges_supplying) { [incoming_exchange, outgoing_exchange] }
          allow(oc).to receive(:coordinator_fees) { double(:coodinator_fees, per_order: [ef3]) }
        end

        context "with order_cycle and distributor set" do
          let(:efc) { EnterpriseFeeCalculator.new(distributor, oc) }
          let(:order) { double(:order, distributor: distributor, order_cycle: oc) }

          it "creates an adjustment for each fee" do
            expect(efc).to receive(:per_order_enterprise_fee_applicators_for).with(order) { [applicator] }
            expect(applicator).to receive(:create_order_adjustment).with(order)
            efc.create_order_adjustments_for order
          end

          it "makes fee applicators for an order" do
            expect(efc.send(:per_order_enterprise_fee_applicators_for, order))
            .to eq [OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, nil, 'supplier'),
                    OpenFoodNetwork::EnterpriseFeeApplicator.new(ef2, nil, 'distributor'),
                    OpenFoodNetwork::EnterpriseFeeApplicator.new(ef3, nil, 'coordinator')]
          end
        end

        context "with no order_cycle or distributor set" do
          let(:efc) { EnterpriseFeeCalculator.new }
          let(:order) { double(:order, distributor: nil, order_cycle: nil) }

          it "does not make applicators for an order" do
            expect(efc.send(:per_order_enterprise_fee_applicators_for, order)).to eq []
          end
        end
      end
    end
  end
end
