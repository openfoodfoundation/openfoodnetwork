# frozen_string_literal: true

require 'system_helper'

describe "Sales Tax Totals By order" do
  #  Scenarion 1: added tax
  #  1 producer
  #  1 distributor
  #  product that costs 100$
  #  shipping costs 10$
  #  the packaging cost is 5$
  #  1 order with 1 line item
  #  the line item match 2 tax rates: country (2.5%) and state (1.5%)
  let!(:table_header){
    [
      "Distributor",
      "Order Cycle",
      "Order Number",
      "Tax Category",
      "Tax Rate Name",
      "Tax Rate",
      "Total excl. Tax ($)",
      "Tax",
      "Total incl. Tax ($)",
      "First Name",
      "Last Name",
      "Code",
      "Email"
    ].join(" ").upcase
  }
  let!(:state_zone){ create(:zone_with_state_member) }
  let!(:country_zone){ create(:zone_with_member) }
  let!(:tax_category){ create(:tax_category, name: 'tax_category') }
  let!(:state_tax_rate){
    create(:tax_rate, zone: state_zone, tax_category: tax_category,
                      name: 'State', amount: 0.015)
  }
  let!(:country_tax_rate){
    create(:tax_rate, zone: country_zone, tax_category: tax_category,
                      name: 'Country', amount: 0.025)
  }
  let!(:ship_address){
    create(:ship_address,
           state: state_zone.members.first.zoneable,
           country: country_zone.members.first.zoneable)
  }

  let!(:variant){ create(:variant) }
  let!(:product){ variant.product }
  let!(:supplier){ create(:supplier_enterprise, name: 'Supplier', charges_sales_tax: true) }
  let!(:distributor){
    create(:distributor_enterprise_with_tax, name: 'Distributor', charges_sales_tax: true)
  }
  let!(:distributor_fee){
    create(:enterprise_fee, :flat_rate, amount: 5,
                                        tax_category_id: tax_category.id,
                                        enterprise_id: distributor.id)
  }
  let!(:payment_method){ create(:payment_method, :flat_rate) }
  let!(:shipping_method){
    create(:shipping_method, :flat_rate, amount: 10, tax_category_id: tax_category.id)
  }

  let!(:order){ create(:order_with_distributor, distributor: distributor) }
  let!(:order_cycle){
    create(:simple_order_cycle, name: 'oc1', suppliers: [supplier], distributors: [distributor],
                                variants: [variant])
  }
  let!(:customer1){
    create(:customer, enterprise: create(:enterprise),
                      user: create(:user),
                      first_name: 'cfname', last_name: 'clname', code: 'ABC123')
  }

  let(:admin){ create(:admin_user) }

  before do
    order_cycle.cached_outgoing_exchanges.first.enterprise_fees << distributor_fee
    distributor.shipping_methods << shipping_method
    distributor.payment_methods << payment_method

    product.update!(
      tax_category_id: tax_category.id,
      supplier_id: supplier.id
    )

    order.update!(
      number: 'ORDER_NUMBER_1',
      order_cycle_id: order_cycle.id,
      ship_address_id: ship_address.id,
      customer_id: customer1.id,
      email: 'order1@example.com'
    )
    order.line_items.create(variant: variant, quantity: 1, price: 100)
  end

  context 'added tax' do
    before do
      # the enterprise fees can be known only when the user selects the variants
      # we'll need to create them by calling recreate_all_fees!
      order.recreate_all_fees!
      OrderWorkflow.new(order).complete!
    end

    it "generates the report" do
      login_as admin
      visit admin_reports_path
      click_on "Sales Tax Totals By Order"

      expect(page).to have_button("Go")
      click_on "Go"
      expect(page.find("table.report__table thead tr").text).to have_content(table_header)

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "oc1",
        "ORDER_NUMBER_1",
        "tax_category",
        "State",
        "1.5 %",
        "115.0",
        "1.73",
        "116.73",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "oc1",
        "ORDER_NUMBER_1",
        "tax_category",
        "Country",
        "2.5 %",
        "115.0",
        "2.88",
        "117.88",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "TOTAL",
        "115.0",
        "4.61",
        "119.61",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" "))
    end
  end

  context 'included tax' do
    before do
      state_tax_rate.update!({ included_in_price: true })
      country_tax_rate.update!({ included_in_price: true })

      order.recreate_all_fees!
      OrderWorkflow.new(order).complete!
    end
    it "generates the report" do
      login_as admin
      visit admin_reports_path
      click_on "Sales Tax Totals By Order"

      expect(page).to have_button("Go")
      click_on "Go"
      expect(page.find("table.report__table thead tr").text).to have_content(table_header)

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "oc1",
        "ORDER_NUMBER_1",
        "tax_category",
        "State",
        "1.5 %",
        "110.5",
        "1.7",
        "112.2",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "oc1",
        "ORDER_NUMBER_1",
        "tax_category",
        "Country",
        "2.5 %",
        "110.5",
        "2.8",
        "113.3",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "TOTAL",
        "110.5",
        "4.5",
        "115.0",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" "))
    end
  end

  context 'should filter by customer' do
    let!(:order2){ create(:order_with_distributor, distributor: distributor) }
    let!(:customer2){ create(:customer, enterprise: create(:enterprise), user: create(:user)) }
    let!(:customer_email_dropdown_selector){ "#s2id_q_customer_id_in" }
    let!(:table_raw_selector){ "table.report__table tbody tr" }
    let(:customer1_country_tax_rate_row){
      [
        "Distributor",
        "oc1",
        "ORDER_NUMBER_1",
        "tax_category",
        "Country",
        "2.5 %",
        "115.0",
        "2.88",
        "117.88",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" ")
    }
    let(:customer1_state_tax_rate_row){
      [
        "Distributor",
        "oc1",
        "ORDER_NUMBER_1",
        "tax_category",
        "State",
        "1.5 %",
        "115.0",
        "1.73",
        "116.73",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" ")
    }
    let(:customer1_summary_row){
      [
        "TOTAL",
        "115.0",
        "4.61",
        "119.61",
        "cfname",
        "clname",
        "ABC123",
        "order1@example.com"
      ].join(" ")
    }

    let(:customer2_country_tax_rate_row){
      [
        "Distributor",
        "oc1",
        "ORDER_NUMBER_2",
        "tax_category",
        "Country",
        "2.5 %",
        "215.0",
        "5.38",
        "220.38",
        "c2fname",
        "c2lname",
        "DEF456",
        "order2@example.com"
      ].join(" ")
    }
    let(:customer2_state_tax_rate_row){
      [
        "Distributor",
        "oc1",
        "ORDER_NUMBER_2",
        "tax_category",
        "State",
        "1.5 %",
        "215.0",
        "3.23",
        "218.23",
        "c2fname",
        "c2lname",
        "DEF456",
        "order2@example.com"
      ].join(" ")
    }
    let(:customer2_summary_row){
      [
        "TOTAL",
        "215.0",
        "8.61",
        "223.61",
        "c2fname",
        "c2lname",
        "DEF456",
        "order2@example.com"
      ].join(" ")
    }

    before do
      order.recreate_all_fees!
      OrderWorkflow.new(order).complete!

      customer2.update!({ first_name: 'c2fname', last_name: 'c2lname', code: 'DEF456' })
      order2.line_items.create({ variant: variant, quantity: 1, price: 200 })
      order2.update!({
                       order_cycle_id: order_cycle.id,
                       ship_address_id: customer2.bill_address_id,
                       customer_id: customer2.id,
                       number: 'ORDER_NUMBER_2',
                       email: 'order2@example.com'
                     })
      order2.recreate_all_fees!
      OrderWorkflow.new(order2).complete!

      login_as admin
      visit admin_reports_path
      click_on "Sales Tax Totals By Order"
    end

    it "should load all the orders" do
      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer1_summary_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer2_summary_row)
      expect(page).to have_selector(table_raw_selector, count: 6)
    end

    it "should filter customer1 orders" do
      pending
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer1.email).click

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer1_summary_row)
      expect(page).to have_selector(table_raw_selector, count: 3)
    end

    it "should filter customer2 orders" do
      pending
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer2.email).click

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer2_summary_row)
      expect(page).to have_selector(table_raw_selector, count: 3)
    end

    it "should filter customer1 and customer2 orders" do
      pending
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer1.email).click
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer2.email).click
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer1_summary_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer2_summary_row)
      expect(page).to have_selector(table_raw_selector, count: 6)
    end

    describe "downloading" do
      context "csv files" do
        let(:report_file_csv) do
          CSV.read("spec/fixtures/reports/sales_tax_by_order/sales_tax_by_order.csv")
        end

        it 'downloads the file' do
          expect(downloaded_filenames.length).to eq(0) # downloads folder should be empty
          select "CSV", from: "report_format"
          click_on "Go"
          wait_for_download
          expect(downloaded_filenames.length).to eq(1) # downloads folder should contain 1 file
          expect(downloaded_filename).to match(/.*\.csv/)
          expect(CSV.read(downloaded_filename)).to eq(report_file_csv)
        end
      end

      context "xlsx files" do
        let(:report_file_xlsx) do
          File.open("spec/fixtures/reports/sales_tax_by_order/sales_tax_by_order.xlsx")
        end

        it 'downloads the file' do
          expect(downloaded_filenames.length).to eq(0) # downloads folder should be empty
          select "Spreadsheet", from: "report_format"
          find("#display_summary_row").uncheck
          click_on "Go"
          wait_for_download
          expect(downloaded_filenames.length).to eq(1) # downloads folder should contain 1 file
          expect(downloaded_filename).to match(/.*\.xlsx/)
          downloaded_content = extract_xlsx_rows(downloaded_filename, 1..5)
          fixture_content = extract_xlsx_rows(report_file_xlsx, 1..5)
          expect(downloaded_content).to eq(fixture_content)
        end

        def extract_xlsx_rows(file, range)
          xlsx = Roo::Excelx.new(file)
          range.map { |i| xlsx.row(i) }
        end
      end

      context "pdf files" do
        it 'downloads the file' do
          expect(downloaded_filenames.length).to eq(0) # downloads folder should be empty
          select "PDF", from: "report_format"
          click_on "Go"
          wait_for_download
          expect(downloaded_filenames.length).to eq(1) # downloads folder should contain 1 file
          expect(downloaded_filename).to match(/.*\.pdf/)
        end
      end
    end
  end
end
