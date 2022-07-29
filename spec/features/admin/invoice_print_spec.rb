# frozen_string_literal: true

require "spec_helper"

describe '
    As an administrator
    I want to print a invoice as PDF
', js: false do
  include WebHelper
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:product) { create(:simple_product) }
  let(:distributor) { create(:distributor_enterprise, owner: user, charges_sales_tax: true) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'One', distributors: [distributor],
                                variants: [product.variants.first])
  end

  let(:order) do
    create(:order_with_totals_and_distribution, user: user, distributor: distributor,
                                                order_cycle: order_cycle, state: 'complete',
                                                payment_state: 'balance_due')
  end

  before do
    stub_request(:get, ->(uri) { uri.to_s.include? "/css/mail" })
  end

  describe "that contains right Payment Description at Checkout information" do
    let!(:payment_method1) do
      create(:stripe_sca_payment_method, distributors: [distributor], description: "description1")
    end
    let!(:payment_method2) do
      create(:stripe_sca_payment_method, distributors: [distributor], description: "description2")
    end

    context "with no payment" do
      it "do not display the payment description information" do
        login_as_admin_and_visit spree.print_admin_order_path(order)
        convert_pdf_to_page
        expect(page).to have_no_content 'Payment Description at Checkout'
      end
    end

    context "with one payment" do
      let!(:payment1) do
        create(:payment, :completed, order: order, payment_method: payment_method1)
      end
      before do
        order.save!
      end

      it "display the payment description section" do
        login_as_admin_and_visit spree.print_admin_order_path(order)
        convert_pdf_to_page
        expect(page).to have_content 'Payment Description at Checkout'
        expect(page).to have_content 'description1'
      end
    end

    context "with two payments, and one that failed" do
      before do
        order.update payments: []
        order.payments << create(:payment, :completed, order: order,
                                                       payment_method: payment_method1,
                                                       created_at: 1.day.ago)
        order.payments << create(:payment, order: order, state: 'failed',
                                           payment_method: payment_method2, created_at: 2.days.ago)
        order.save!
      end

      it "display the payment description section and use the one from the completed payment" do
        login_as_admin_and_visit spree.print_admin_order_path(order)
        convert_pdf_to_page
        expect(page).to have_content 'Payment Description at Checkout'
        expect(page).to have_content 'description1'
      end
    end

    context "with two completed payments" do
      before do
        order.update payments: []
        order.payments << create(:payment, :completed, order: order,
                                                       payment_method: payment_method1,
                                                       created_at: 2.days.ago)
        order.payments << create(:payment, :completed, order: order,
                                                       payment_method: payment_method2,
                                                       created_at: 1.day.ago)
        order.save!
      end

      it "display the payment description section and use the one from the last payment" do
        login_as_admin_and_visit spree.print_admin_order_path(order)
        convert_pdf_to_page
        expect(page).to have_content 'Payment Description at Checkout'
        expect(page).to have_content 'description2'
      end
    end
  end

  shared_examples "Check display on each invoice: legacy and alternative" do |alternative_invoice|
    let!(:completed_order) do
      create(:completed_order_with_fees, distributor: distributor, order_cycle: order_cycle,
                                         user: create(:user, email: "xxxxxx@example.com"),
                                         bill_address: create(:address, phone: '1234567890'))
    end

    before do
      allow(Spree::Config).to receive(:invoice_style2?).and_return(alternative_invoice)
      login_as_admin_and_visit spree.print_admin_order_path(completed_order)
      convert_pdf_to_page
    end

    it "display phone number and email of the customer" do
      expect(page).to have_content "1234567890"
      expect(page).to have_content "xxxxxx@example.com"
    end
  end

  it_behaves_like "Check display on each invoice: legacy and alternative", false
  it_behaves_like "Check display on each invoice: legacy and alternative", true

  describe "an order with added taxes" do
    let!(:order) do
      create(:order_with_taxes, distributor: distributor, ship_address: create(:address),
                                line_items_count: 0,
                                product_price: 10, tax_rate_amount: 0.2,
                                included_in_price: false,
                                tax_rate_name: "Veggies").tap do |order|
                                  order.create_tax_charge!
                                  order.update_shipping_fees!
                                  order.save
                                end
    end

    context "legacy invoice" do
      before do
        allow(Spree::Config).to receive(:invoice_style2?).and_return(false)
        login_as_admin_and_visit spree.print_admin_order_path(order)
      end
      it "displays the taxes correctly" do
        convert_pdf_to_page
        expect(page).to have_content "GST Total: $2.00"
      end
    end
  end
end

def convert_pdf_to_page
  temp_pdf = Tempfile.new('pdf')
  temp_pdf << page.source.force_encoding('UTF-8')
  reader = PDF::Reader.new(temp_pdf)
  pdf_text = reader.pages.map(&:text)
  temp_pdf.close
  page.driver.response.instance_variable_set('@body', pdf_text)
end
