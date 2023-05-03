# frozen_string_literal: true

require 'system_helper'

describe "Enterprise Summary Fee with Tax Report By Producer" do
  #   1 order cycle has:
  #     - coordinator fees price 20
  #     - incoming exchange fees 15
  #     - outgoing exchange fees 10
  #     - cost of line items     100
  #   tax
  #       country: 2.5%
  #       state: 1.5%

  let!(:table_header){
    ["Distributor", "Producer", "Producer Tax Status", "Order Cycle", "Name", "Type", "Owner",
     "Tax Category", "Tax Rate Name", "Tax Rate", "Total excl. tax ($)", "Tax",
     "Total incl. tax ($)"].join(" ").upcase
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
  let!(:ship_address){ create(:ship_address) }

  let!(:supplier_owner) { create(:user, enterprise_limit: 1) }
  let!(:supplier2_owner) { create(:user, enterprise_limit: 1) }
  let!(:supplier){
    create(:supplier_enterprise, name: 'Supplier', charges_sales_tax: true,
                                 owner_id: supplier_owner.id)
  }
  let!(:supplier2){
    create(:supplier_enterprise, name: 'Supplier2', charges_sales_tax: true,
                                 owner_id: supplier2_owner.id)
  }
  let!(:product){ create(:simple_product, supplier: supplier ) }
  let!(:product2){ create(:simple_product, supplier: supplier2 ) }
  let!(:variant){ create(:variant, product_id: product.id, tax_category: tax_category) }
  let!(:variant2){ create(:variant, product_id: product2.id, tax_category: tax_category) }
  let!(:distributor_owner) { create(:user, enterprise_limit: 1) }
  let!(:distributor){
    create(:distributor_enterprise_with_tax, name: 'Distributor', owner_id: distributor_owner.id)
  }
  let!(:payment_method){ create(:payment_method, :flat_rate) }
  let!(:shipping_method){ create(:shipping_method, :flat_rate) }

  let!(:order_cycle){
    create(:simple_order_cycle, distributors: [distributor], name: "oc1")
  }
  let!(:enterprise_relationship1) {
    create(:enterprise_relationship, parent: supplier, child: distributor,
                                     permissions_list: [:add_to_order_cycle])
  }
  let!(:enterprise_relationship2) {
    create(:enterprise_relationship, parent: supplier2, child: distributor,
                                     permissions_list: [:add_to_order_cycle])
  }

  let(:admin) { create(:admin_user) }

  let(:coordinator_fees){
    create(:enterprise_fee, :flat_rate, enterprise: distributor, amount: 20,
                                        name: 'Adminstration',
                                        fee_type: 'admin',
                                        tax_category: tax_category)
  }
  let(:supplier_fees){
    create(:enterprise_fee, :per_item, enterprise: supplier, amount: 15,
                                       name: 'Transport',
                                       fee_type: 'transport',
                                       tax_category: tax_category)
  }
  let(:supplier_fees2){
    create(:enterprise_fee, :per_item, enterprise: supplier2, amount: 25,
                                       name: 'Sales',
                                       fee_type: 'sales',
                                       tax_category: tax_category)
  }
  let(:distributor_fee){
    create(:enterprise_fee, :flat_rate, enterprise: distributor, amount: 10,
                                        name: 'Packing',
                                        fee_type: 'packing',
                                        tax_category: tax_category)
  }

  let!(:incoming_exchange1) {
    order_cycle.exchanges.create! sender: supplier, receiver: distributor, incoming: true
  }

  let!(:incoming_exchange2) {
    order_cycle.exchanges.create! sender: supplier2, receiver: distributor, incoming: true
  }
  let(:outgoing_exchange) {
    order_cycle.exchanges.create! sender: distributor, receiver: distributor, incoming: false
  }

  let!(:order){ create(:order_with_distributor, distributor: distributor) }
  before do
    order_cycle.coordinator_fees << coordinator_fees
    order_cycle.exchanges.incoming.first.exchange_fees.create!(enterprise_fee: supplier_fees)
    order_cycle.exchanges.incoming.first.exchange_variants.create!(variant: variant)
    order_cycle.exchanges.incoming.second.exchange_fees.create!(enterprise_fee: supplier_fees2)
    order_cycle.exchanges.incoming.second.exchange_variants.create!(variant: variant2)
    order_cycle.exchanges.outgoing.first.exchange_fees.create!(enterprise_fee: distributor_fee)
    order_cycle.exchanges.outgoing.first.exchange_variants.create!(variant: variant)
    order_cycle.exchanges.outgoing.first.exchange_variants.create!(variant: variant2)

    distributor.shipping_methods << shipping_method
    distributor.payment_methods << payment_method

    product.update!({
                      tax_category_id: tax_category.id,
                      supplier_id: supplier.id
                    })
    product2.update!({
                       tax_category_id: tax_category.id,
                       supplier_id: supplier2.id
                     })
  end

  context 'added tax' do
    #   1 order cycle has:
    #     - coordinator fees  (20) 1.5% = 0.30, 2.5% = 0.50
    #     - incoming exchange (15) 1.5% = 0.38, 2.5% = 0.63
    #     - outgoing exchange (10) 1.5% = 0.15, 2.5% = 0.25
    #     - line items        (50) 1.5% = 0.75, 2.5% = 1.25

    context "an order with line items from a single supplier (1)" do
      before do
        order.line_items.create({ variant: variant, quantity: 1, price: 100 })
        order.update!({
                        order_cycle_id: order_cycle.id,
                        ship_address_id: ship_address.id
                      })
        # This will load the enterprise fees from the order cycle.
        # This is needed because the order instance was created
        # independently of the order_cycle.
        order.recreate_all_fees!
        while !order.completed?
          break unless order.next!
        end
      end

      let(:coordinator_state_tax){
        ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
         "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
      }
      let(:coordinator_country_tax){
        ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
         "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
      }

      let(:supplier_state_tax){
        ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
         "tax_category", "State", "0.015", "15.0", "0.23", "15.23"].join(" ")
      }
      let(:supplier_country_tax){
        ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
         "tax_category", "Country", "0.025", "15.0", "0.38", "15.38"].join(" ")
      }

      let(:distributor_state_tax){
        ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
         "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
      }
      let(:distributor_country_tax){
        ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
         "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
      }

      let(:cost_of_produce){
        ["Distributor", "Supplier", "Yes", "oc1", "Cost of produce", "line items", "Supplier",
         "100.0", "4.0", "104.0"].join(" ")
      }
      let(:summary_row){
        [
          "TOTAL", # Fees and line items
          "145.0", # Tax excl: 20 + 15 + 10 + 100
          "5.81",  # Tax     : (0.30 + 0.50) + (0.23 + 0.38) + (0.15 + 0.25) + (1.50 + 2.50)
          "150.81" # Tax incl: 145.00 + 5.81
        ].join(" ")
      }

      it 'generates the report and displays fees for the respective supplier' do
        login_as distributor_owner
        visit admin_reports_path
        click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

        expect(page).to have_button("Go")
        click_on "Go"
        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).to have_content(supplier_state_tax)
        expect(table).to have_content(supplier_country_tax)
        expect(table).to have_content(distributor_state_tax)
        expect(table).to have_content(distributor_country_tax)
        expect(table).to have_content(coordinator_state_tax)
        expect(table).to have_content(coordinator_country_tax)
        expect(table).to have_content(cost_of_produce)
        expect(table).to have_content(summary_row)
      end

      context "filtering" do
        let(:fee_name_selector){ "#s2id_q_enterprise_fee_id_in" }
        let(:fee_owner_selector){ "#s2id_q_enterprise_fee_owner_id_in" }

        let(:summary_row_after_filtering_by_fee_name){
          ["TOTAL", "120.0", "4.8", "124.8"].join(" ")
        }

        let(:summary_row_after_filtering_by_fee_owner){
          ["TOTAL", "115.0", "4.61", "119.61"].join(" ")
        }

        it "should filter by fee name" do
          login_as distributor.owner
          visit admin_reports_path
          click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

          page.find(fee_name_selector).click
          find('li', text: coordinator_fees.name).click

          expect(page).to have_button("Go")
          click_on "Go"

          expect(page.find("table.report__table thead tr")).to have_content(table_header)

          table = page.find("table.report__table tbody")
          expect(table).to_not have_content(supplier_state_tax)
          expect(table).to_not have_content(supplier_country_tax)
          expect(table).to_not have_content(distributor_state_tax)
          expect(table).to_not have_content(distributor_country_tax)
          expect(table).to have_content(coordinator_state_tax)
          expect(table).to have_content(coordinator_country_tax)
          expect(table).to have_content(cost_of_produce)
          expect(table).to have_content(summary_row_after_filtering_by_fee_name)
        end

        it "should filter by fee owner" do
          login_as distributor.owner
          visit admin_reports_path
          click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

          page.find(fee_owner_selector).click
          find('li', text: supplier.name).click

          expect(page).to have_button("Go")
          click_on "Go"

          expect(page.find("table.report__table thead tr")).to have_content(table_header)

          table = page.find("table.report__table tbody")
          expect(table).to have_content(supplier_state_tax)
          expect(table).to have_content(supplier_country_tax)
          expect(table).to_not have_content(distributor_state_tax)
          expect(table).to_not have_content(distributor_country_tax)
          expect(table).to_not have_content(coordinator_state_tax)
          expect(table).to_not have_content(coordinator_country_tax)
          expect(table).to have_content(cost_of_produce)
          expect(table).to have_content(summary_row_after_filtering_by_fee_owner)
        end
      end

    end

    context "an order with line items from a single supplier (2)" do
      before do
        order.line_items.create({ variant: variant2, quantity: 1, price: 50 })
        order.update!({
                        order_cycle_id: order_cycle.id,
                        ship_address_id: ship_address.id
                      })
        # This will load the enterprise fees from the order cycle.
        # This is needed because the order instance was created
        # independently of the order_cycle.
        order.recreate_all_fees!
        while !order.completed?
          break unless order.next!
        end
      end

      let(:coordinator_state_tax){
        ["Distributor", "Supplier2", "Yes", "oc1", "Adminstration", "admin", "Distributor",
         "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
      }
      let(:coordinator_country_tax){
        ["Distributor", "Supplier2", "Yes", "oc1", "Adminstration", "admin", "Distributor",
         "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
      }

      let(:supplier_state_tax){
        ["Distributor", "Supplier2", "Yes", "oc1", "Sales", "sales", "Supplier2",
         "tax_category", "State", "0.015", "25.0", "0.38", "25.38"].join(" ")
      }
      let(:supplier_country_tax){
        ["Distributor", "Supplier2", "Yes", "oc1", "Sales", "sales", "Supplier2",
         "tax_category", "Country", "0.025", "25.0", "0.63", "25.63"].join(" ")
      }

      let(:distributor_state_tax){
        ["Distributor", "Supplier2", "Yes", "oc1", "Packing", "packing", "Distributor",
         "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
      }
      let(:distributor_country_tax){
        ["Distributor", "Supplier2", "Yes", "oc1", "Packing", "packing", "Distributor",
         "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
      }

      let(:cost_of_produce){
        ["Distributor", "Supplier2", "Yes", "oc1", "Cost of produce", "line items", "Supplier2",
         "50.0", "2.0", "52.0"].join(" ")
      }
      let(:summary_row){
        [
          "TOTAL", # Fees and line items
          "105.0", # Tax excl: 20 + 25 + 10 + 50
          "4.21",  # Tax     : (0.30 + 0.50) + (0.38 + 0.63) + (0.15 + 0.25) + 2
          "109.21" # Tax incl: 105 + 4.21
        ].join(" ")
      }

      it 'generates the report and displays fees for the respective supplier' do
        login_as distributor_owner
        visit admin_reports_path
        click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

        expect(page).to have_button("Go")
        click_on "Go"
        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).to have_content(supplier_state_tax)
        expect(table).to have_content(supplier_country_tax)
        expect(table).to have_content(distributor_state_tax)
        expect(table).to have_content(distributor_country_tax)
        expect(table).to have_content(coordinator_state_tax)
        expect(table).to have_content(coordinator_country_tax)
        expect(table).to have_content(cost_of_produce)
        expect(table).to have_content(summary_row)
      end
    end
  end

  context 'included tax' do
    #   1 order cycle has:
    #     - coordinator fees  (20) 1.5% = 0.30, 2.5% = 0.50
    #     - incoming exchange (15) 1.5% = 0.23, 2.5% = 0.38
    #     - outgoing exchange (10) 1.5% = 0.15, 2.5% = 0.25
    #     - line items       (100) 1.5% = 1.50, 2.5% = 2.50

    before do
      state_tax_rate.update!({ included_in_price: true })
      country_tax_rate.update!({ included_in_price: true })

      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: ship_address.id
                    })
      order.recreate_all_fees!
      while !order.completed?
        break unless order.next!
      end
    end

    let(:coordinator_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "19.21", "0.3", "19.51"].join(" ")
    }
    let(:coordinator_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "19.21", "0.49", "19.7"].join(" ")
    }

    let(:supplier_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
       "tax_category", "State", "0.015", "14.41", "0.22", "14.63"].join(" ")
    }
    let(:supplier_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
       "tax_category", "Country", "0.025", "14.41", "0.37", "14.78"].join(" ")
    }

    let(:distributor_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "9.61", "0.15", "9.76"].join(" ")
    }
    let(:distributor_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "9.61", "0.24", "9.85"].join(" ")
    }

    let(:cost_of_produce){
      ["Distributor", "Supplier", "Yes", "oc1", "Cost of produce", "line items", "Supplier",
       "96.08", "3.92", "100.0"].join(" ")
    }
    let(:summary_row){
      ["TOTAL", "139.31", "5.69", "145.0"].join(" ")
    }

    it 'generates the report' do
      login_as admin
      visit admin_reports_path
      click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr")).to have_content(table_header)

      table = page.find("table.report__table tbody")
      expect(table).to have_content(supplier_state_tax)
      expect(table).to have_content(supplier_country_tax)
      expect(table).to have_content(distributor_state_tax)
      expect(table).to have_content(distributor_country_tax)
      expect(table).to have_content(coordinator_state_tax)
      expect(table).to have_content(coordinator_country_tax)
      expect(table).to have_content(cost_of_produce)
      expect(table).to have_content(summary_row)
    end
  end
end
