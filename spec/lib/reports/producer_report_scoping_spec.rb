# frozen_string_literal: true

# Producers who don't sell were given the sales tax and Xero invoices reports when report
# access was opened to every enterprise manager. These reports must still only show orders
# the producer is permitted to see.
RSpec.describe "Order-based reports run by a producer" do
  let(:producer) { create(:supplier_enterprise, sells: "none") }
  let(:hub) { create(:distributor_enterprise) }
  let(:order) { create(:completed_order_with_totals, distributor: hub) }

  before do
    order.line_items.first.variant.update!(enterprise_id: producer.id)
  end

  def sales_tax_orders(user)
    Reporting::Reports::SalesTax::SalesTaxTotalsByOrder.new(user, {}).search.result
  end

  def xero_orders(user)
    Reporting::Reports::XeroInvoices::Base.new(user, {}).search.result
  end

  context "when the hub doesn't let producers edit orders" do
    it "doesn't show the hub's orders to the producer" do
      expect(sales_tax_orders(producer.owner)).to be_empty
      expect(xero_orders(producer.owner)).to be_empty
    end

    it "shows the order to the hub" do
      expect(sales_tax_orders(hub.owner)).to include order
      expect(xero_orders(hub.owner)).to include order
    end
  end
end
