# frozen_string_literal: true

require "system_helper"

describe '
    As an administrator
    I want numbers, all the numbers!
' do
  include WebHelper
  include AuthenticationHelper

  context "Permissions for different reports" do
    context "As an enterprise user" do
      let(:user) do
        create(:user, enterprises: [create(:distributor_enterprise)])
      end

      it "does not show super admin only report" do
        login_to_admin_as user
        click_link "Reports"
        expect(page).not_to have_content "Users & Enterprises"
      end
    end

    context "As an admin user" do
      it "shows the super admin only report" do
        login_to_admin_section
        click_link "Reports"
        expect(page).to have_content "Users & Enterprises"
      end
    end
  end

  describe "Can access Customers reports and generate customers report" do
    before do
      login_as_admin_and_visit admin_reports_path
    end

    it "customers report" do
      click_link "Mailing List"
      click_button "Go"

      rows = find("table.report__table").all("thead tr")
      table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
      expect(table.sort).to eq([
        ["Email", "First Name", "Last Name", "Suburb"].map(&:upcase)
      ].sort)
    end

    it "customers report" do
      click_link "Addresses"
      click_button "Go"

      rows = find("table.report__table").all("thead tr")
      table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
      expect(table.sort).to eq([
        ["First Name", "Last Name", "Billing Address", "Email", "Phone", "Hub", "Hub Address",
         "Shipping Method"].map(&:upcase)
      ].sort)
    end
  end

  describe "Order cycle management report" do
    before do
      login_as_admin_and_visit admin_reports_path
    end

    it "payment method report" do
      click_link "Payment Methods Report"
      click_button "Go"
      rows = find("table.report__table").all("thead tr")
      table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
      expect(table.sort).to eq([
        ["First Name", "Last Name", "Hub", "Customer Code", "Email", "Phone", "Shipping Method",
         "Payment Method", "Amount", "Balance"].map(&:upcase)
      ].sort)
    end

    it "delivery report" do
      click_link "Delivery Report"
      click_button "Go"
      rows = find("table.report__table").all("thead tr")
      table = rows.map { |r| r.all("th").map { |c| c.text.strip } }
      expect(table.sort).to eq([
        ["First Name", "Last Name", "Hub", "Customer Code", "Delivery Address", "Delivery Postcode",
         "Phone", "Shipping Method", "Payment Method", "Amount", "Balance",
         "Temp Controlled Items?", "Special Instructions"].map(&:upcase)
      ].sort)
    end
  end

  context "for a complete, paid order" do
    let!(:ready_to_ship_order) { create(:order_ready_to_ship) }

    before do
      login_as_admin_and_visit admin_reports_path
    end

    it "generates the orders and distributors report" do
      click_link 'Orders And Distributors'
      click_button 'Go'

      rows = find("table.report__table").all("thead tr")
      table_headers = rows.map { |r| r.all("th").map { |c| c.text.strip } }

      expect(table_headers).to eq([
                                    ['Order date',
                                     'Order Id',
                                     'Customer Name',
                                     'Customer Email',
                                     'Customer Phone',
                                     'Customer City',
                                     'SKU',
                                     'Item name',
                                     'Variant',
                                     'Quantity',
                                     'Max Quantity',
                                     'Cost',
                                     'Shipping Cost',
                                     'Payment Method',
                                     'Distributor',
                                     'Distributor address',
                                     'Distributor city',
                                     'Distributor postcode',
                                     'Shipping Method',
                                     'Shipping instructions']
                                           .map(&:upcase)
                                  ])

      expect(all('table.report__table tbody tr').count).to eq(
        Spree::LineItem.where(
          order_id: ready_to_ship_order.id # Total rows should equal number of line items, per order
        ).count
      )
    end

    it "generates the payments reports" do
      click_link 'Payments By Type'
      click_button 'Go'

      rows = find("table.report__table").all("thead tr")
      table_headers = rows.map { |r| r.all("th").map { |c| c.text.strip } }

      expect(table_headers).to eq([
                                    ['Payment State',
                                     'Distributor',
                                     'Payment Type',
                                     "Total (%s)" % currency_symbol]
                                           .map(&:upcase)
                                  ])

      expect(all('table.report__table tbody tr').count).to eq(
        Spree::Payment.where(
          order_id: ready_to_ship_order.id # Total rows should equal number of payments, per order
        ).count
      )
    end
  end

  context "sales tax report" do
    let(:distributor1) {
      create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true)
    }
    let(:distributor2) {
      create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true)
    }
    let(:user1) { create(:user, enterprises: [distributor1]) }
    let(:user2) { create(:user, enterprises: [distributor2]) }
    let(:shipping_tax_rate) { create(:tax_rate, amount: 0.20, included_in_price: true, zone: zone) }
    let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
    let!(:shipping_method) {
      create(:shipping_method_with, :expensive_name, distributors: [distributor1],
                                                     tax_category: shipping_tax_category)
    }
    let(:enterprise_fee) {
      create(:enterprise_fee, enterprise: user1.enterprises.first,
                              tax_category: product2.tax_category,
                              calculator: Calculator::FlatRate.new(preferred_amount: 120.0))
    }
    let(:order_cycle) {
      create(:simple_order_cycle, coordinator: distributor1,
                                  coordinator_fees: [enterprise_fee], distributors: [distributor1],
                                  variants: [product1.variants.first, product2.variants.first])
    }

    let!(:zone) { create(:zone_with_member) }
    let(:address) { create(:address) }
    let(:order1) {
      create(:order, order_cycle: order_cycle, distributor: user1.enterprises.first,
                     ship_address: address, bill_address: address)
    }
    let(:product1) {
      create(:taxed_product, zone: zone, price: 12.54, tax_rate_amount: 0, included_in_price: true)
    }
    let(:product2) {
      create(:taxed_product, zone: zone, price: 500.15, tax_rate_amount: 0.2,
                             included_in_price: true)
    }

    let!(:line_item1) {
      create(:line_item, variant: product1.variants.first, price: 12.54, quantity: 1, order: order1)
    }
    let!(:line_item2) {
      create(:line_item, variant: product2.variants.first, price: 500.15, quantity: 3,
                         order: order1)
    }

    before do
      order1.reload
      break unless order1.next! until order1.delivery?

      order1.select_shipping_method(shipping_method.id)
      order1.recreate_all_fees!
      break unless order1.next! until order1.payment?

      create(:payment, state: "checkout", order: order1, amount: order1.reload.total,
                       payment_method: create(:payment_method, distributors: [distributor1]))
      break unless order1.next! until order1.complete?

      login_as_admin_and_visit admin_reports_path
    end

    it "generate Tax Types reports" do
      click_link "Tax Types"
      click_button "Go"

      # Then it should give me access only to managed enterprises
      expect(page).to     have_select 'q_distributor_id_eq',
                                      with_options: [user1.enterprises.first.name]
      expect(page).not_to have_select 'q_distributor_id_eq',
                                      with_options: [user2.enterprises.first.name]

      # When I filter to just one distributor
      select user1.enterprises.first.name, from: 'q_distributor_id_eq'
      click_button 'Go'

      # Then I should see the relevant order
      expect(page).to have_content order1.number.to_s

      # And the totals and sales tax should be correct
      expect(page).to have_content "1512.99" # items total
      expect(page).to have_content "1500.45" # taxable items total
      expect(page).to have_content "250.08" # sales tax
      expect(page).to have_content "20.0" # enterprise fee tax

      # And the shipping cost and tax should be correct
      expect(page).to have_content "100.55" # shipping cost
      expect(page).to have_content "16.76" # shipping tax

      # And the total tax should be correct
      expect(page).to have_content "286.84" # total tax
    end

    it "generate Tax Rates report" do
      click_link "Tax Rates"
      click_button "Go"

      expect(page).to have_css(".report__table thead th", text: "20.0% ($)")
      expect(page).to have_css(".report__table thead th", text: "0.0% ($)")
      expect(page).to have_table_row [order1.number.to_s, "1446.7", "16.76", "0", "270.08",
                                      "286.84", "1733.54"]
    end
  end

  describe "products and inventory report" do
    let(:supplier) { create(:supplier_enterprise, name: 'Supplier Name') }
    let(:taxon)    { create(:taxon, name: 'Taxon Name') }
    let(:product1) {
      create(:simple_product, name: "Product Name", price: 100, supplier: supplier,
                              primary_taxon: taxon)
    }
    let(:product2) {
      create(:simple_product, name: "Product 2", price: 99.0, variant_unit: 'weight',
                              variant_unit_scale: 1, unit_value: '100', supplier: supplier,
                              primary_taxon: taxon, sku: "product_sku")
    }
    let(:variant1) { product1.variants.first }
    let(:variant2) { create(:variant, product: product1, price: 80.0) }
    let(:variant3) { product2.variants.first }

    before do
      product1.set_property 'Organic', 'NASAA 12345'
      product2.set_property 'Organic', 'NASAA 12345'
      product1.taxons = [taxon]
      product2.taxons = [taxon]
      variant1.on_hand = 10
      variant1.update!(sku: "sku1")
      variant2.on_hand = 20
      variant2.update!(sku: "sku2")
      variant3.on_hand = 9
      variant3.update!(sku: "")
      variant1.option_values = [create(:option_value, presentation: "Test")]
      variant2.option_values = [create(:option_value, presentation: "Something")]
    end

    it "shows products and inventory report" do
      login_as_admin_and_visit admin_reports_path

      expect(page).to have_content "All products"
      expect(page).to have_content "Inventory (on hand)"
      click_link 'All products'
      click_button "Go"
      expect(page).to have_content "Supplier"
      expect(page).to have_table_row ["Supplier", "Producer Suburb", "Product",
                                      "Product Properties", "Taxons", "Variant Value", "Price",
                                      "Group Buy Unit Quantity", "Amount", "SKU"].map(&:upcase)
      expect(page).to have_table_row [product1.supplier.name, product1.supplier.address.city,
                                      "Product Name",
                                      product1.properties.map(&:presentation).join(", "),
                                      product1.primary_taxon.name, "Test", "100.0",
                                      "none", "", "sku1"]
      expect(page).to have_table_row [product1.supplier.name, product1.supplier.address.city,
                                      "Product Name",
                                      product1.properties.map(&:presentation).join(", "),
                                      product1.primary_taxon.name, "Something", "80.0",
                                      "none", "", "sku2"]
      expect(page).to have_table_row [product2.supplier.name, product1.supplier.address.city,
                                      "Product 2",
                                      product1.properties.map(&:presentation).join(", "),
                                      product2.primary_taxon.name, "100g", "99.0",
                                      "none", "", "product_sku"]
    end

    it "shows the LettuceShare report" do
      login_as_admin_and_visit admin_reports_path
      click_link 'LettuceShare'
      click_button "Go"

      expect(page).to have_table_row ['PRODUCT', 'Description', 'Qty', 'Pack Size', 'Unit',
                                      'Unit Price', 'Total', 'GST incl.',
                                      'Grower and growing method', 'Taxon'].map(&:upcase)
      expect(page).to have_table_row ['Product 2', '100g', '', '100', 'g', '99.0', '', '0',
                                      'Supplier Name (Organic - NASAA 12345)', 'Taxon Name']
    end
  end

  describe "users and enterprises report" do
    let!(:enterprise1) { create( :enterprise, owner: create(:user) ) }
    let!(:enterprise2) { create( :enterprise, owner: create(:user) ) }
    let!(:enterprise3) { create( :enterprise, owner: create(:user) ) }

    before do
      enterprise3.enterprise_roles.build( user: enterprise1.owner ).save

      login_as_admin_and_visit admin_reports_path

      click_link 'Users & Enterprises'
    end

    it "shows users and enterprises report" do
      click_button "Go"

      rows = find("table.report__table").all("tr")
      table = rows.map { |r| r.all("th,td").map { |c| c.text.strip }[0..2] }

      expect(table.sort).to eq([
        ["User", "Relationship", "Enterprise"].map(&:upcase),
        [enterprise1.owner.email, "owns", enterprise1.name],
        [enterprise1.owner.email, "manages", enterprise1.name],
        [enterprise2.owner.email, "owns", enterprise2.name],
        [enterprise2.owner.email, "manages", enterprise2.name],
        [enterprise3.owner.email, "owns", enterprise3.name],
        [enterprise3.owner.email, "manages", enterprise3.name],
        [enterprise1.owner.email, "manages", enterprise3.name]
      ].sort)
    end

    it "filters the list" do
      select enterprise3.name, from:  "enterprise_id_in"
      select enterprise1.owner.email, from: "user_id_in"

      click_button "Go"

      rows = find("table.report__table").all("tr")
      table = rows.map { |r| r.all("th,td").map { |c| c.text.strip }[0..2] }

      expect(table.sort).to eq([
        ["User", "Relationship", "Enterprise"].map(&:upcase),
        [enterprise1.owner.email, "manages", enterprise3.name]
      ].sort)
    end
  end

  describe 'bulk coop report' do
    before do
      login_as_admin_and_visit admin_reports_path
    end

    it "generating Bulk Co-op Supplier Report" do
      click_link "Bulk Co-op Supplier Report"
      click_button "Go"

      expect(page).to have_table_row [
        "Supplier",
        "Product",
        "Bulk Unit Size",
        "Variant",
        "Variant Value",
        "Variant Unit",
        "Weight",
        "Sum Total",
        "Units Required",
        "Unallocated",
        "Max Quantity Excess"
      ].map(&:upcase)
    end

    it "generating Bulk Co-op Allocation report" do
      click_link "Bulk Co-op Allocation"
      click_button "Go"

      expect(page).to have_table_row [
        "Customer",
        "Product",
        "Bulk Unit Size",
        "Variant",
        "Variant Value",
        "Variant Unit",
        "Weight",
        "Sum Total",
        "Total available",
        "Unallocated",
        "Max Quantity Excess"
      ].map(&:upcase)
    end

    it "generating Bulk Co-op Packing Sheets report" do
      click_link "Bulk Co-op Packing Sheets"
      click_button "Go"

      expect(page).to have_table_row [
        "Customer",
        "Product",
        "Variant",
        "Sum Total"
      ].map(&:upcase)
    end

    it "generating Bulk Co-op Customer Payments report" do
      click_link "Bulk Co-op Customer Payments"
      click_button "Go"

      expect(page).to have_table_row [
        "Customer",
        "Date of Order",
        "Total Cost",
        "Amount Owing",
        "Amount Paid"
      ].map(&:upcase)
    end
  end

  describe "Xero invoices report" do
    let(:distributor1) {
      create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true)
    }
    let(:distributor2) {
      create(:distributor_enterprise, with_payment_and_shipping: true, charges_sales_tax: true)
    }
    let(:user1) { create(:user, enterprises: [distributor1]) }
    let(:user2) { create(:user, enterprises: [distributor2]) }
    let(:shipping_method) { create(:shipping_method_with, :expensive_name) }
    let(:shipment) { create(:shipment_with, :shipping_method, shipping_method: shipping_method) }

    let(:enterprise_fee1) {
      create(:enterprise_fee, enterprise: user1.enterprises.first,
                              tax_category: product2.tax_category,
                              calculator: Calculator::FlatRate.new(preferred_amount: 10))
    }
    let(:enterprise_fee2) {
      create(:enterprise_fee, enterprise: user1.enterprises.first,
                              tax_category: product2.tax_category,
                              calculator: Calculator::FlatRate.new(preferred_amount: 20))
    }
    let(:order_cycle) {
      create(:simple_order_cycle, coordinator: distributor1,
                                  coordinator_fees: [enterprise_fee1, enterprise_fee2],
                                  distributors: [distributor1], variants: [product1.master])
    }

    let!(:zone) { create(:zone_with_member) }
    let(:bill_address) {
      create(:address, firstname: 'Customer', lastname: 'Name', address1: 'customer l1',
                       address2: '', city: 'customer city', zipcode: 1234)
    }
    let(:order1) {
      create(:order, order_cycle: order_cycle, distributor: user1.enterprises.first,
                     shipments: [shipment], bill_address: bill_address)
    }
    let(:product1) {
      create(:taxed_product, zone: zone, price: 12.54, tax_rate_amount: 0, sku: 'sku1')
    }
    let(:product2) {
      create(:taxed_product, zone: zone, price: 500.15, tax_rate_amount: 0.2, sku: 'sku2')
    }

    describe "with adjustments" do
      let!(:line_item1) {
        create(:line_item, variant: product1.variants.first, price: 12.54, quantity: 1,
                           order: order1)
      }
      let!(:line_item2) {
        create(:line_item, variant: product2.variants.first, price: 500.15, quantity: 3,
                           order: order1)
      }

      let!(:tax_category) { create(:tax_category) }
      let!(:tax_rate) { create(:tax_rate, tax_category: tax_category) }
      let!(:adj_shipping) {
        create(:adjustment, order: order1, adjustable: order1, label: "Shipping",
                            originator: shipping_method, amount: 100.55)
      }
      let!(:adj_fee1) {
        create(:adjustment, order: order1, adjustable: order1, originator: enterprise_fee1,
                            label: "Enterprise fee untaxed", amount: 10)
      }
      let!(:adj_fee2) {
        create(:adjustment, order: order1, adjustable: order1, originator: enterprise_fee2,
                            label: "Enterprise fee taxed", amount: 20, tax_category: tax_category)
      }
      let!(:adj_fee2_tax) {
        create(:adjustment, order: order1, adjustable: adj_fee2, originator: tax_rate, amount: 3,
                            state: "closed")
      }
      let!(:adj_admin1) {
        create(:adjustment, order: order1, adjustable: order1, originator: nil,
                            label: "Manual adjustment", amount: 30)
      }
      let!(:adj_admin2) {
        create(:adjustment, order: order1, adjustable: order1, originator: nil,
                            label: "Manual adjustment", amount: 40, tax_category: tax_category)
      }

      before do
        order1.update_order!
        order1.update!(email: 'customer@email.com')
        order1.shipment.update(included_tax_total: 10.06)
        Timecop.travel(Time.zone.local(2021, 4, 25, 14, 0, 0)) { order1.finalize! }
        order1.reload
        order1.create_tax_charge!
      end

      around do |example|
        Timecop.travel(Time.zone.local(2021, 4, 26, 14, 0, 0)) do
          example.run
        end
      end

      context "summary report" do
        before do
          login_as_admin_and_visit admin_reports_path
          click_link "Summary"
          click_button 'Go'
        end

        it "shows Xero invoices report" do
          expect(xero_invoice_table).to match_table [
            xero_invoice_header,
            xero_invoice_summary_row('Total untaxable produce (no tax)',       12.54,
                                     'GST Free Income'),
            xero_invoice_summary_row('Total taxable produce (tax inclusive)',  1500.45,
                                     'GST on Income'),
            xero_invoice_summary_row('Total untaxable fees (no tax)',          10.0,
                                     'GST Free Income'),
            xero_invoice_summary_row('Total taxable fees (tax inclusive)',     20.0,
                                     'GST on Income'),
            xero_invoice_summary_row('Delivery Shipping Cost (tax inclusive)', 100.55,
                                     'GST on Income'),
            xero_invoice_summary_row('Total untaxable admin adjustments (no tax)',      30.0,
                                     'GST Free Income'),
            xero_invoice_summary_row('Total taxable admin adjustments (tax inclusive)', 40.0,
                                     'GST on Income')
          ]
        end

        it "can customise a number of fields" do
          fill_in 'initial_invoice_number', with: '5'

          pick_datetime '#invoice_date', Date.new(2021, 2, 12)
          pick_datetime '#due_date', Date.new(2021, 3, 12)

          fill_in 'account_code', with: 'abc123'
          click_button 'Go'

          opts = { invoice_number: '5', invoice_date: '2021-02-12',
                   due_date: '2021-03-12', account_code: 'abc123' }

          expect(xero_invoice_table).to match_table [
            xero_invoice_header,
            xero_invoice_summary_row('Total untaxable produce (no tax)',       12.54,
                                     'GST Free Income', opts),
            xero_invoice_summary_row('Total taxable produce (tax inclusive)',  1500.45,
                                     'GST on Income',   opts),
            xero_invoice_summary_row('Total untaxable fees (no tax)',          10.0,
                                     'GST Free Income', opts),
            xero_invoice_summary_row('Total taxable fees (tax inclusive)',     20.0,
                                     'GST on Income',   opts),
            xero_invoice_summary_row('Delivery Shipping Cost (tax inclusive)', 100.55,
                                     'GST on Income',   opts),
            xero_invoice_summary_row('Total untaxable admin adjustments (no tax)',      30.0,
                                     'GST Free Income', opts),
            xero_invoice_summary_row('Total taxable admin adjustments (tax inclusive)', 40.0,
                                     'GST on Income',   opts)
          ]
        end
      end

      context "detailed report" do
        before do
          login_as_admin_and_visit admin_reports_path
          click_link "Detailed"
          click_button 'Go'
        end

        it "generates a detailed report" do
          login_as_admin_and_visit admin_reports_path
          click_link "Detailed"
          click_button 'Go'

          opts = {}

          expect(xero_invoice_table).to match_table [
            xero_invoice_header,
            xero_invoice_li_row(line_item1),
            xero_invoice_li_row(line_item2),
            xero_invoice_adjustment_row(adj_admin1),
            xero_invoice_adjustment_row(adj_admin2),
            xero_invoice_summary_row('Total untaxable fees (no tax)',          10.0,
                                     'GST Free Income', opts),
            xero_invoice_summary_row('Total taxable fees (tax inclusive)',     20.0,
                                     'GST on Income',   opts),
            xero_invoice_summary_row('Delivery Shipping Cost (tax inclusive)', 100.55,
                                     'GST on Income',   opts)
          ]
        end
      end
    end

    private

    def xero_invoice_table
      find("table.report__table")
    end

    def xero_invoice_header
      %w(*ContactName EmailAddress POAddressLine1 POAddressLine2 POAddressLine3 POAddressLine4
         POCity PORegion POPostalCode POCountry *InvoiceNumber Reference *InvoiceDate
         *DueDate InventoryItemCode *Description *Quantity *UnitAmount Discount *AccountCode
         *TaxType TrackingName1 TrackingOption1 TrackingName2 TrackingOption2 Currency BrandingTheme
         Paid?).map(&:upcase)
    end

    def xero_invoice_summary_row(description, amount, tax_type, opts = {})
      xero_invoice_row '', description, amount, '1', tax_type, opts
    end

    def xero_invoice_li_row(line_item, opts = {})
      tax_type = line_item.has_tax? ? 'GST on Income' : 'GST Free Income'
      xero_invoice_row line_item.product.sku, line_item.product_and_full_name,
                       line_item.price.to_s, line_item.quantity.to_s, tax_type, opts
    end

    def xero_invoice_adjustment_row(adjustment, opts = {})
      tax_type = adjustment.has_tax? ? 'GST on Income' : 'GST Free Income'
      xero_invoice_row('', adjustment.label, adjustment.amount, '1', tax_type, opts)
    end

    def xero_invoice_row(sku, description, amount, quantity, tax_type, opts = {})
      opts.reverse_merge!(customer_name: 'Customer Name', address1: 'customer l1',
                          city: 'customer city', state: 'Victoria', zipcode: '1234',
                          country: 'Australia', invoice_number: order1.number,
                          order_number: order1.number, invoice_date: '2021-04-26',
                          due_date: '2021-05-26', account_code: 'food sales')

      [opts[:customer_name], 'customer@email.com', opts[:address1], '', '', '',
       opts[:city], opts[:state], opts[:zipcode], opts[:country], opts[:invoice_number],
       opts[:order_number], opts[:invoice_date], opts[:due_date],

       sku,
       description,
       quantity,
       amount.to_s, '', opts[:account_code], tax_type, '', '', '', '', Spree::Config.currency,
       '', 'N']
    end
  end
end
