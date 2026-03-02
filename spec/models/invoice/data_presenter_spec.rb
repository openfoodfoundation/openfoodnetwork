# frozen_string_literal: true

RSpec.describe Invoice::DataPresenter do
  context "#display_date" do
    let(:invoice) { double(:invoice, date: '2023-08-01') }

    let(:presenter) { Invoice::DataPresenter.new(invoice) }
    it "prints in a format" do
      expect(presenter.display_date).to eq "August 01, 2023"
    end
  end

  context "#display_line_item_tax_rate" do
    let!(:order){
      create(:order_with_taxes,
             product_price: 100,
             tax_rate_name: "VAT",
             tax_rate_amount: 0.15)
    }
    let(:non_taxable_line_item) { order.line_items.first }
    let(:taxable_line_item) { order.line_items.last } # only the last item one has tax rate
    let(:invoice){ order.invoices.latest }
    let(:presenter){ Invoice::DataPresenter.new(invoice) }
    before do
      order.create_tax_charge!
      Orders::GenerateInvoiceService.new(order).generate_or_update_latest_invoice
    end

    it "displays nothing when the line item refer to a non taxable product" do
      expect(presenter.display_line_item_tax_rate(non_taxable_line_item)).to eq ""
    end

    it "displays the tax rate when the line item refer to a taxable product" do
      expect(presenter.display_line_item_tax_rate(taxable_line_item)).to eq "15.0%"
    end

    context "if multiple tax rates belong to the tax category" do
      let(:taxable_line_item_tax_rate){
        order.line_items.last.tax_category.tax_rates.first
      }
      let(:tax_rate_calculator){
        taxable_line_item_tax_rate.calculator
      }
      before do
        tax_rate_clone = taxable_line_item_tax_rate.dup.tap do |dup|
          dup.amount = 0.20
          dup.calculator = tax_rate_calculator.dup.tap do |calc|
            calc.calculable = dup
          end
        end
        tax_rate_clone.save!
        tax_rate_clone.calculator.save!
        order.create_tax_charge!
        Orders::GenerateInvoiceService.new(order).generate_or_update_latest_invoice
      end

      it "displays the tax rate when the line item refer to a taxable product" do
        expect(order.invoices.count).to eq 2
        expect(presenter.display_line_item_tax_rate(taxable_line_item)).to eq "15.0%, 20.0%"
      end

      context "one of the tax rate is applicable to a different tax zone" do
        before do
          new_zone = create(:zone, default_tax: false, member: Spree::Country.last)
          order.line_items.last.tax_category.tax_rates.last.update!(zone: new_zone)
          order.create_tax_charge!
          Orders::GenerateInvoiceService.new(order).generate_or_update_latest_invoice
        end

        it "displays only the tax rates that were applied to the line items" do
          expect(order.invoices.count).to eq 3
          expect(presenter.display_line_item_tax_rate(taxable_line_item)).to eq "15.0%"
        end
      end
    end
  end
end
