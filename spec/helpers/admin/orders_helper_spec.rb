# frozen_string_literal: true

RSpec.describe Admin::OrdersHelper do
  describe "#order_adjustments_for_display" do
    let(:order) { create(:order) }
    let(:service) { instance_double(VoucherAdjustmentsService, voucher_included_tax:) }
    let(:voucher_included_tax) { 0.0 }

    before do
      allow(VoucherAdjustmentsService).to receive(:new).and_return(service)
    end

    it "selects eligible adjustments" do
      adjustment = create(:adjustment, order:, adjustable: order, amount: 1)

      expect(helper.order_adjustments_for_display(order)).to eq [adjustment]
    end

    it "filters shipping method adjustments" do
      create(:adjustment, order:, adjustable: build(:shipment), amount: 1,
                          originator_type: "Spree::ShippingMethod")

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters ineligible payment adjustments" do
      create(:adjustment, adjustable: build(:payment), amount: 0, eligible: false,
                          originator_type: "Spree::PaymentMethod", order:)

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    it "filters out line item adjustments" do
      create(:adjustment, adjustable: build(:line_item), amount: 0, eligible: false,
                          originator_type: "EnterpriseFee", order:)

      expect(helper.order_adjustments_for_display(order)).to eq []
    end

    context "with a voucher with tax included in price" do
      let(:enterprise) { build(:enterprise) }
      let(:voucher) do
        create(:voucher_flat_rate, code: 'new_code', enterprise:, amount: 10)
      end
      let(:voucher_included_tax) { -0.5 }

      it "includes a fake tax voucher adjustment" do
        voucher_adjustment = voucher.create_adjustment(voucher.code, order)
        voucher_adjustment.update(included_tax: voucher_included_tax)

        fake_adjustment = helper.order_adjustments_for_display(order).last
        expect(fake_adjustment.label).to eq("new_code (tax included in voucher)")
        expect(fake_adjustment.amount).to eq(-0.5)
      end
    end

    context "with additional tax total" do
      let!(:shipping_method){ create(:free_shipping_method) }
      let!(:enterprise){
        create(:distributor_enterprise_with_tax, name: 'Enterprise', charges_sales_tax: true,
                                                 shipping_methods: [shipping_method])
      }
      let!(:country_zone){ create(:zone_with_member) }
      let!(:tax_category){ create(:tax_category, name: 'tax_category') }
      let!(:tax_rate){
        create(:tax_rate, zone: country_zone, tax_category:, name: 'Tax Rate', amount: 0.13,
                          included_in_price: false)
      }
      let!(:ship_address){ create(:ship_address) }
      let!(:product) {
        create(:simple_product, supplier_id: enterprise.id, price: 10,
                                tax_category_id: tax_category.id)
      }
      let!(:variant){
        create(:variant, :with_order_cycle, product:, distributor: enterprise, order_cycle:,
                                            tax_category:)
      }
      let!(:coordinator_fees){
        create(:enterprise_fee, :flat_percent_per_item, enterprise:, amount: 20,
                                                        name: 'Adminstration',
                                                        fee_type: 'sales',
                                                        tax_category:)
      }
      let!(:order_cycle){
        create(:simple_order_cycle, name: "oc1", suppliers: [enterprise],
                                    distributors: [enterprise],
                                    coordinator_fees: [coordinator_fees])
      }
      let!(:order){
        create(:order_with_distributor, distributor: enterprise, order_cycle:, ship_address:)
      }
      let!(:line_item) { create(:line_item, variant:, quantity: 1, price: 10, order:) }

      before do
        order_cycle.variants << [product.variants.first]
        order_cycle.exchanges.outgoing.first.variants << product.variants.first

        order.recreate_all_fees!
        Orders::WorkflowService.new(order).complete!
      end

      it "includes additional tax on fees" do
        adjustment = order_adjustments_for_display(order).first
        expect(adjustment.label).to eq("Tax on fees")
        expect(adjustment.amount).to eq(0.26)
      end
    end
  end
end
