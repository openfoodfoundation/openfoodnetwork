# frozen_string_literal: true

require 'system_helper'

describe "Enterprise Summary Fee with Tax Report By Producer" do
  #   1 order cycle has:
  #     - coordinator fees price 20
  #     - incoming exchange fees 15
  #     - outgoing exchange fees 10
  #     - cost of line items     100 (supplier 1)
  #     - cost of line items     50  (supplier 2)
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
  let(:included_in_price) { false }
  let!(:state_tax_rate){
    create(:tax_rate, zone: state_zone, tax_category:,
                      name: 'State', amount: 0.015, included_in_price:)
  }
  let!(:country_tax_rate){
    create(:tax_rate, zone: country_zone, tax_category:,
                      name: 'Country', amount: 0.025, included_in_price:)
  }
  let!(:ship_address){ create(:ship_address) }

  let!(:supplier_owner) { create(:user, enterprise_limit: 1) }
  let!(:supplier2_owner) { create(:user, enterprise_limit: 1) }
  let!(:supplier){
    create(:supplier_enterprise, name: 'Supplier1', charges_sales_tax: true,
                                 owner_id: supplier_owner.id)
  }
  let!(:supplier2){
    create(:supplier_enterprise, name: 'Supplier2', charges_sales_tax: true,
                                 owner_id: supplier2_owner.id)
  }
  let!(:product){ create(:simple_product, supplier: ) }
  let!(:product2){ create(:simple_product, supplier: supplier2 ) }
  let!(:variant){ create(:variant, product_id: product.id, tax_category:) }
  let!(:variant2){ create(:variant, product_id: product2.id, tax_category:) }
  let!(:distributor_owner) { create(:user, enterprise_limit: 1) }
  let!(:distributor){
    distributor = create(:distributor_enterprise_with_tax, name: 'Distributor',
                                                           owner_id: distributor_owner.id)

    distributor.shipping_methods << shipping_method
    distributor.payment_methods << payment_method

    distributor
  }
  let!(:payment_method){ create(:payment_method, :flat_rate) }
  let!(:shipping_method){ create(:shipping_method, :flat_rate) }

  let!(:order_cycle){
    order_cycle = create(:simple_order_cycle, distributors: [distributor], name: "oc1")

    # creates exchanges for oc1
    order_cycle.exchanges.create! sender: supplier, receiver: distributor, incoming: true
    order_cycle.exchanges.create! sender: supplier2, receiver: distributor, incoming: true

    # adds variants to exchanges on oc1
    order_cycle.coordinator_fees << coordinator_fees
    order_cycle.exchanges.incoming.first.exchange_fees.create!(enterprise_fee: supplier_fees)
    order_cycle.exchanges.incoming.first.exchange_variants.create!(variant:)
    order_cycle.exchanges.incoming.second.exchange_fees.create!(enterprise_fee: supplier_fees2)
    order_cycle.exchanges.incoming.second.exchange_variants.create!(variant: variant2)
    order_cycle.exchanges.outgoing.first.exchange_fees.create!(enterprise_fee: distributor_fee)
    order_cycle.exchanges.outgoing.first.exchange_variants.create!(variant:)
    order_cycle.exchanges.outgoing.first.exchange_variants.create!(variant: variant2)

    order_cycle
  }
  let!(:order_cycle2){
    order_cycle2 = create(:simple_order_cycle, distributors: [distributor], name: "oc2")

    # creates exchanges for oc2
    order_cycle2.exchanges.create! sender: supplier, receiver: distributor, incoming: true
    order_cycle2.exchanges.create! sender: supplier2, receiver: distributor, incoming: true

    # adds variants to exchanges on oc2
    order_cycle2.coordinator_fees << coordinator_fees
    order_cycle2.exchanges.incoming.first.exchange_fees.create!(enterprise_fee: supplier_fees)
    order_cycle2.exchanges.incoming.first.exchange_variants.create!(variant:)
    order_cycle2.exchanges.incoming.second.exchange_fees.create!(enterprise_fee: supplier_fees2)
    order_cycle2.exchanges.incoming.second.exchange_variants.create!(variant: variant2)
    order_cycle2.exchanges.outgoing.first.exchange_fees.create!(enterprise_fee: distributor_fee)
    order_cycle2.exchanges.outgoing.first.exchange_variants.create!(variant:)
    order_cycle2.exchanges.outgoing.first.exchange_variants.create!(variant: variant2)

    order_cycle2
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
                                        tax_category:)
  }
  let(:supplier_fees){
    create(:enterprise_fee, :per_item, enterprise: supplier, amount: 15,
                                       name: 'Transport',
                                       fee_type: 'transport',
                                       tax_category:)
  }
  let(:supplier_fees2){
    create(:enterprise_fee, :per_item, enterprise: supplier2, amount: 25,
                                       name: 'Sales',
                                       fee_type: 'sales',
                                       tax_category:)
  }
  let(:distributor_fee){
    create(:enterprise_fee, :flat_rate, enterprise: distributor, amount: 10,
                                        name: 'Packing',
                                        fee_type: 'packing',
                                        tax_category:)
  }

  # creates orders for for oc1 and oc2
  let!(:order) {
    order = create(:order_with_distributor, distributor:, order_cycle_id: order_cycle.id,
                                            ship_address_id: ship_address.id)

    order.line_items.create({ variant:, quantity: 1, price: 100 })

    # This will load the enterprise fees from the order cycle.
    # This is needed because the order instance was created
    # independently of the order_cycle.
    order.recreate_all_fees!
    while !order.completed?
      break unless order.next!
    end
    order
  }

  let!(:order2) {
    order2 = create(:order_with_distributor, distributor:, order_cycle_id: order_cycle2.id,
                                             ship_address_id: ship_address.id)

    order2.line_items.create({ variant: variant2, quantity: 1, price: 50 })

    # This will load the enterprise fees from the order cycle.
    # This is needed because the order instance was created
    # independently of the order_cycle.
    order2.recreate_all_fees!
    while !order2.completed?
      break unless order2.next!
    end

    order2
  }

  before do
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
    # 1st - incoming exchange (15) 1.5% = 0.23, 2.5% = 0.38
    # 2nd - incoming exchange (25) 1.5% = 0.38, 2.5% = 0.63
    #     - outgoing exchange (10) 1.5% = 0.15, 2.5% = 0.25
    #     - line items        (50) 1.5% = 0.75, 2.5% = 1.25

    describe "orders" do
      # for supplier 1, oc1

      let(:coordinator_state_tax1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin", "Distributor",
         "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
      }
      let(:coordinator_country_tax1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin", "Distributor",
         "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
      }

      let(:supplier_state_tax1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport", "Supplier1",
         "tax_category", "State", "0.015", "15.0", "0.23", "15.23"].join(" ")
      }
      let(:supplier_country_tax1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport", "Supplier1",
         "tax_category", "Country", "0.025", "15.0", "0.38", "15.38"].join(" ")
      }

      let(:distributor_state_tax1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing", "Distributor",
         "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
      }
      let(:distributor_country_tax1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing", "Distributor",
         "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
      }

      let(:cost_of_produce1){
        ["Distributor", "Supplier1", "Yes", "oc1", "Cost of produce", "line items", "Supplier1",
         "100.0", "4.0", "104.0"].join(" ")
      }
      let(:summary_row1){
        [
          cost_of_produce1, # Ensure summary row follows the right supplier
          "TOTAL", # Fees and line items
          "115.0", # Tax excl: 15 + 100
          "4.61",  # Tax     : (0.23 + 0.38) + (1.50 + 2.50)
          "119.61" # Tax incl: 100.00 + 15 + (0.23 + 0.38) + (1.50 + 2.50)
        ].join(" ")
      }

      # for supplier 2, oc2
      let(:coordinator_state_tax2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Adminstration", "admin", "Distributor",
         "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
      }
      let(:coordinator_country_tax2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Adminstration", "admin", "Distributor",
         "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
      }

      let(:supplier_state_tax2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Sales", "sales", "Supplier2",
         "tax_category", "State", "0.015", "25.0", "0.38", "25.38"].join(" ")
      }
      let(:supplier_country_tax2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Sales", "sales", "Supplier2",
         "tax_category", "Country", "0.025", "25.0", "0.63", "25.63"].join(" ")
      }

      let(:distributor_state_tax2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Packing", "packing", "Distributor",
         "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
      }
      let(:distributor_country_tax2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Packing", "packing", "Distributor",
         "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
      }

      let(:cost_of_produce2){
        ["Distributor", "Supplier2", "Yes", "oc2", "Cost of produce", "line items", "Supplier2",
         "50.0", "2.0", "52.0"].join(" ")
      }
      let(:summary_row2){
        [
          cost_of_produce2, # Ensure summary row follows the right supplier
          "TOTAL", # Fees and line items
          "75.0", # Tax excl: 25 + 50
          "3.01", # Tax     : (0.38 + 0.63) + 2
          "78.01" # Tax incl: 25 + 50 + 4.21
        ].join(" ")
      }

      context "with line items from a single supplier" do
        it 'generates the report and displays fees for the respective suppliers' do
          visit_report
          run_report

          expect(page.find("table.report__table thead tr")).to have_content(table_header)

          table = page.find("table.report__table tbody")
          expect(table).to have_content(supplier_state_tax1)
          expect(table).to have_content(supplier_country_tax1)
          expect(table).not_to have_content(distributor_state_tax1)
          expect(table).not_to have_content(distributor_country_tax1)
          expect(table).not_to have_content(coordinator_state_tax1)
          expect(table).not_to have_content(coordinator_country_tax1)
          expect(table).to have_content(cost_of_produce1)
          expect(table).to have_content(summary_row1)

          expect(table).to have_content(supplier_state_tax2)
          expect(table).to have_content(supplier_country_tax2)
          expect(table).not_to have_content(distributor_state_tax2)
          expect(table).not_to have_content(distributor_country_tax2)
          expect(table).not_to have_content(coordinator_state_tax2)
          expect(table).not_to have_content(coordinator_country_tax2)
          expect(table).to have_content(cost_of_produce2)
          expect(table).to have_content(summary_row2)
        end

        context "filtering" do
          before do
            visit_report
          end

          it "should filter by distributor and order cycle" do
            page.find("#s2id_autogen1").click
            find('li', text: distributor.name).click # selects Distributor

            page.find("#s2id_q_order_cycle_id_in").click
            find('li', text: order_cycle.name).click

            run_report
            expect(page.find("table.report__table thead tr")).to have_content(table_header)

            table = page.find("table.report__table tbody")

            expect(table).to have_content(supplier_state_tax1)
            expect(table).to have_content(supplier_country_tax1)
            expect(table).not_to have_content(distributor_state_tax1)
            expect(table).not_to have_content(distributor_country_tax1)
            expect(table).not_to have_content(coordinator_state_tax1)
            expect(table).not_to have_content(coordinator_country_tax1)
            expect(table).to have_content(cost_of_produce1)
            expect(table).to have_content(summary_row1)
          end
        end
      end

      context "with line items from several suppliers" do
        # creates oc3 and order
        let!(:order_cycle3){
          create(:simple_order_cycle, distributors: [distributor], name: "oc3")
        }
        let!(:order3) { create(:order_with_distributor, distributor:) }

        # creates exchanges on oc3
        let!(:incoming_exchange5) {
          order_cycle3.exchanges.create! sender: supplier, receiver: distributor, incoming: true
        }
        let!(:incoming_exchange6) {
          order_cycle3.exchanges.create! sender: supplier2, receiver: distributor, incoming: true
        }
        let(:outgoing_exchange3) {
          order_cycle3.exchanges.create! sender: distributor, receiver: distributor,
                                         incoming: false
        }

        before do
          # adds variants to exchanges on oc3
          order_cycle3.coordinator_fees << coordinator_fees
          order_cycle3.exchanges.incoming.first.exchange_fees.create!(enterprise_fee: supplier_fees)
          order_cycle3.exchanges.incoming.first.exchange_variants.create!(variant:)
          order_cycle3.exchanges.incoming.second.exchange_fees
            .create!(enterprise_fee: supplier_fees2)
          order_cycle3.exchanges.incoming.second.exchange_variants.create!(variant: variant2)
          order_cycle3.exchanges.outgoing.first.exchange_fees
            .create!(enterprise_fee: distributor_fee)
          order_cycle3.exchanges.outgoing.first.exchange_variants.create!(variant:)
          order_cycle3.exchanges.outgoing.first.exchange_variants.create!(variant: variant2)

          # adds line items to the order on oc3
          order3.line_items.create({ variant:, quantity: 1, price: 100 })
          order3.line_items.create({ variant: variant2, quantity: 1, price: 50 })
          order3.update!({
                           order_cycle_id: order_cycle3.id,
                           ship_address_id: ship_address.id
                         })
          # This will load the enterprise fees from the order cycle.
          # This is needed because the order instance was created
          # independently of the order_cycle.
          order3.recreate_all_fees!
          while !order3.completed?
            break unless order3.next!
          end
        end

        # table lines for supplier1

        # for supplier 1, oc3

        let(:coordinator_state_tax3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Adminstration", "admin", "Distributor",
           "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
        }
        let(:coordinator_country_tax3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Adminstration", "admin", "Distributor",
           "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
        }

        let(:supplier_state_tax3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Transport", "transport", "Supplier1",
           "tax_category", "State", "0.015", "15.0", "0.23", "15.23"].join(" ")
        }
        let(:supplier_country_tax3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Transport", "transport", "Supplier1",
           "tax_category", "Country", "0.025", "15.0", "0.38", "15.38"].join(" ")
        }

        let(:distributor_state_tax3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Packing", "packing", "Distributor",
           "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
        }
        let(:distributor_country_tax3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Packing", "packing", "Distributor",
           "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
        }

        let(:cost_of_produce3){
          ["Distributor", "Supplier1", "Yes", "oc3", "Cost of produce", "line items", "Supplier1",
           "100.0", "4.0", "104.0"].join(" ")
        }
        let(:summary_row3){
          [
            cost_of_produce3, # Ensure summary row follows the right supplier
            "TOTAL", # Fees and line items
            "115.0", # Tax excl: 15 + 100
            "4.61",  # Tax     : (0.23 + 0.38) + (1.50 + 2.50)
            "119.61" # Tax incl: 100.00 + 15 + (0.23 + 0.38) + (1.50 + 2.50)
          ].join(" ")
        }

        # for supplier 2, oc3
        let(:coordinator_state_tax4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Adminstration", "admin", "Distributor",
           "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
        }
        let(:coordinator_country_tax4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Adminstration", "admin", "Distributor",
           "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
        }

        let(:supplier_state_tax4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Sales", "sales", "Supplier2",
           "tax_category", "State", "0.015", "25.0", "0.38", "25.38"].join(" ")
        }
        let(:supplier_country_tax4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Sales", "sales", "Supplier2",
           "tax_category", "Country", "0.025", "25.0", "0.63", "25.63"].join(" ")
        }

        let(:distributor_state_tax4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Packing", "packing", "Distributor",
           "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
        }
        let(:distributor_country_tax4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Packing", "packing", "Distributor",
           "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
        }

        let(:cost_of_produce4){
          ["Distributor", "Supplier2", "Yes", "oc3", "Cost of produce", "line items", "Supplier2",
           "50.0", "2.0", "52.0"].join(" ")
        }
        let(:summary_row4){
          [
            cost_of_produce4, # Ensure summary row follows the right supplier
            "TOTAL", # Fees and line items
            "75.0", # Tax excl: 25 + 50
            "3.01", # Tax     : (0.38 + 0.63) + 2
            "78.01" # Tax incl: 25 + 50 + 4.21
          ].join(" ")
        }

        context "filtering" do
          let(:fee_name_selector){ "#s2id_q_enterprise_fee_id_in" }
          let(:fee_owner_selector){ "#s2id_q_enterprise_fee_owner_id_in" }

          let(:summary_row_after_filtering_by_fee_name){
            [cost_of_produce1, "TOTAL", "120.0", "4.8", "124.8"].join(" ")
          }

          let(:summary_row_after_filtering_by_fee_owner){
            [cost_of_produce1, "TOTAL", "115.0", "4.61", "119.61"].join(" ")
          }

          before do
            visit_report
          end

          it "should filter by distributor and order cycle" do
            page.find("#s2id_autogen1").click
            find('li', text: distributor.name).click # selects Distributor

            page.find("#s2id_q_order_cycle_id_in").click
            find('li', text: order_cycle3.name).click

            run_report
            expect(page.find("table.report__table thead tr")).to have_content(table_header)

            table = page.find("table.report__table tbody")

            # Supplier1
            expect(table).to have_content(supplier_state_tax3)
            expect(table).to have_content(supplier_country_tax3)
            expect(table).not_to have_content(distributor_state_tax3)
            expect(table).not_to have_content(distributor_country_tax3)
            expect(table).not_to have_content(coordinator_state_tax3)
            expect(table).not_to have_content(coordinator_country_tax3)
            expect(table).to have_content(cost_of_produce3)
            expect(table).to have_content(summary_row3)

            # Supplier2
            expect(table).to have_content(supplier_state_tax4)
            expect(table).to have_content(supplier_country_tax4)
            expect(table).not_to have_content(distributor_state_tax4)
            expect(table).not_to have_content(distributor_country_tax4)
            expect(table).not_to have_content(coordinator_state_tax4)
            expect(table).not_to have_content(coordinator_country_tax4)
            expect(table).to have_content(cost_of_produce4)
            expect(table).to have_content(summary_row4)
          end

          it "should filter by producer" do
            page.find("#s2id_supplier_id_in").click
            find('li', text: supplier2.name).click

            run_report
            expect(page.find("table.report__table thead tr")).to have_content(table_header)

            table = page.find("table.report__table tbody")

            expect(table).to have_content(supplier_state_tax2)
            expect(table).to have_content(supplier_country_tax2)
            expect(table).not_to have_content(distributor_state_tax2)
            expect(table).not_to have_content(distributor_country_tax2)
            expect(table).not_to have_content(coordinator_state_tax2)
            expect(table).not_to have_content(coordinator_country_tax2)
            expect(table).to have_content(cost_of_produce2)
            expect(table).to have_content(summary_row2)

            expect(table).to_not have_content(supplier_state_tax1)
            expect(table).to_not have_content(supplier_country_tax1)
            expect(table).to_not have_content(cost_of_produce1)
            expect(table).to_not have_content(summary_row1)
          end

          it "should filter by fee name" do
            page.find(fee_name_selector).click
            find('li', text: supplier_fees.name).click

            run_report

            expect(page.find("table.report__table thead tr")).to have_content(table_header)

            table = page.find("table.report__table tbody")

            expect(table).to have_content(supplier_state_tax1)
            expect(table).to have_content(supplier_country_tax1)
            expect(table).to_not have_content(distributor_state_tax1)
            expect(table).to_not have_content(distributor_country_tax1)
            expect(table).to_not have_content(coordinator_state_tax1)
            expect(table).to_not have_content(coordinator_country_tax1)
            expect(table).to have_content(cost_of_produce1)
            expect(table).to have_content(summary_row1)

            expect(table).to have_content(supplier_state_tax3)
            expect(table).to have_content(supplier_country_tax3)
            expect(table).to_not have_content(distributor_state_tax3)
            expect(table).to_not have_content(distributor_country_tax3)
            expect(table).to_not have_content(coordinator_state_tax3)
            expect(table).to_not have_content(coordinator_country_tax3)
            expect(table).to have_content(cost_of_produce3)
            expect(table).to have_content(summary_row3)
          end

          it "should filter by fee owner" do
            page.find(fee_owner_selector).click
            find('li', text: supplier.name).click

            run_report
            expect(page.find("table.report__table thead tr")).to have_content(table_header)

            table = page.find("table.report__table tbody")
            expect(table).to have_content(supplier_state_tax1)
            expect(table).to have_content(supplier_country_tax1)
            expect(table).to_not have_content(distributor_state_tax1)
            expect(table).to_not have_content(distributor_country_tax1)
            expect(table).to_not have_content(coordinator_state_tax1)
            expect(table).to_not have_content(coordinator_country_tax1)
            expect(table).to have_content(cost_of_produce1)
            expect(table).to have_content(summary_row_after_filtering_by_fee_owner)
          end
        end
      end
    end
  end

  context 'included tax' do
    #   1 order cycle has:
    #     - coordinator fees  (20) 1.5% = 0.30, 2.5% = 0.50
    #     - incoming exchange (15) 1.5% = 0.23, 2.5% = 0.38
    #     - outgoing exchange (10) 1.5% = 0.15, 2.5% = 0.25
    #     - line items       (100) 1.5% = 1.50, 2.5% = 2.50
    #     - line items        (50) 1.5% = 1.50, 2.5% = 2.50

    let(:included_in_price) { true }

    let(:coordinator_state_tax1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "19.21", "0.3", "19.51"].join(" ")
    }
    let(:coordinator_country_tax1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "19.21", "0.49", "19.7"].join(" ")
    }

    let(:supplier_state_tax1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport", "Supplier1",
       "tax_category", "State", "0.015", "14.41", "0.22", "14.63"].join(" ")
    }
    let(:supplier_country_tax1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport", "Supplier1",
       "tax_category", "Country", "0.025", "14.41", "0.37", "14.78"].join(" ")
    }

    let(:distributor_state_tax1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "9.61", "0.15", "9.76"].join(" ")
    }
    let(:distributor_country_tax1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "9.61", "0.24", "9.85"].join(" ")
    }

    let(:cost_of_produce1){
      ["Distributor", "Supplier1", "Yes", "oc1", "Cost of produce", "line items", "Supplier1",
       "96.08", "3.92", "100.0"].join(" ")
    }
    let(:summary_row1){
      [
        cost_of_produce1,
        "TOTAL", # Fees and line items
        "110.49", # Tax excl: 14.41 + 96.08
        "4.51", # Tax     : (0.22 + 0.37) + 3.92
        "115.0" # Tax incl: 15 + 100
      ].join(" ")
    }

    # for supplier 2, oc3
    let(:coordinator_state_tax2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "19.21", "0.3", "19.51"].join(" ")
    }
    let(:coordinator_country_tax2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "19.21", "0.49", "19.7"].join(" ")
    }

    let(:supplier_state_tax2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Sales", "sales", "Supplier2",
       "tax_category", "State", "0.015", "24.02", "0.37", "24.39"].join(" ")
    }
    let(:supplier_country_tax2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Sales", "sales", "Supplier2",
       "tax_category", "Country", "0.025", "24.02", "0.61", "24.63"].join(" ")
    }

    let(:distributor_state_tax2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "9.61", "0.15", "9.76"].join(" ")
    }
    let(:distributor_country_tax2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "9.61", "0.24", "9.85"].join(" ")
    }

    let(:cost_of_produce2){
      ["Distributor", "Supplier2", "Yes", "oc2", "Cost of produce", "line items", "Supplier2",
       "48.04", "1.96", "50.0"].join(" ")
    }
    let(:summary_row2){
      [
        cost_of_produce2,
        "TOTAL", # Fees and line items
        "72.06", # Tax excl: 24.02 + 48.04
        "2.94", # Tax     : (0.37 + 0.61) + 1.96
        "75.0" # Tax incl: 25 + 50
      ].join(" ")
    }

    context "with line items from a single supplier" do
      it 'generates the report and displays fees for the respective suppliers' do
        visit_report
        run_report

        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).to have_content(supplier_state_tax1)
        expect(table).to have_content(supplier_country_tax1)
        expect(table).not_to have_content(distributor_state_tax1)
        expect(table).not_to have_content(distributor_country_tax1)
        expect(table).not_to have_content(coordinator_state_tax1)
        expect(table).not_to have_content(coordinator_country_tax1)
        expect(table).to have_content(cost_of_produce1)
        expect(table).to have_content(summary_row1)

        expect(table).to have_content(supplier_state_tax2)
        expect(table).to have_content(supplier_country_tax2)
        expect(table).not_to have_content(distributor_state_tax2)
        expect(table).not_to have_content(distributor_country_tax2)
        expect(table).not_to have_content(coordinator_state_tax2)
        expect(table).not_to have_content(coordinator_country_tax2)
        expect(table).to have_content(cost_of_produce2)
        expect(table).to have_content(summary_row2)
      end
    end
  end

  context 'multiple orders, same enterprise fee, different tax rates' do
    let(:another_state) {
      Spree::State.find_by(name: "New South Wales")
    }

    let(:another_address) {
      create(:address,
             state: another_state,
             country: another_state.country)
    }

    let!(:state_zone2){
      create(
        :zone,
        zone_members: [Spree::ZoneMember.new(zoneable: another_state)]
      )
    }

    let!(:state_tax_rate2){
      create(:tax_rate, zone: state_zone2, tax_category:,
                        name: 'Another State Tax', amount: 0.02, included_in_price:)
    }

    let!(:order2) {
      # Ensure tax rates set up first
      state_tax_rate2

      order2 = create(:order_with_distributor, distributor:, order_cycle_id: order_cycle.id,
                                               ship_address_id: another_address.id)

      # adds a line items to the order on oc2
      order2.line_items.create({ variant:, quantity: 1, price: 50 })
      order2.recreate_all_fees!
      while !order2.completed?
        break unless order2.next!
      end

      order2
    }

    context "added tax" do
      let(:admin_state_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin",
          "Distributor", "tax_category", "State", "0.015", "20.0", "0.3", "20.3"
        ].join(" ")
      }
      let(:admin_country_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin",
          "Distributor", "tax_category", "Country", "0.025", "40.0", "1.0", "41.0"
        ].join(" ")
      }
      let(:transport_state_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport",
          "Supplier1", "tax_category", "State", "0.015", "15.0", "0.23", "15.23"
        ].join(" ")
      }
      let(:transport_country_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport",
          "Supplier1", "tax_category", "Country", "0.025", "30.0", "0.76", "30.76"
        ].join(" ")
      }
      let(:packing_state_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing",
          "Distributor", "tax_category", "State", "0.015", "10.0", "0.15", "10.15"
        ].join(" ")
      }
      let(:packing_country_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing",
          "Distributor", "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"
        ].join(" ")
      }

      let(:admin_state_tax2){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin",
          "Distributor", "tax_category", "Another State Tax", "0.02", "20.0", "0.4", "20.4"
        ].join(" ")
      }
      let(:transport_state_tax2){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport",
          "Supplier1", "tax_category", "Another State Tax", "0.02", "15.0", "0.3", "15.3"
        ].join(" ")
      }
      let(:packing_state_tax2){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing",
          "Distributor", "tax_category", "Another State Tax", "0.02", "10.0", "0.2", "10.2"
        ].join(" ")
      }

      let(:supplier1_cost_of_produce_line_items){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Cost of produce line items",
          "Supplier1", "150.0", "6.25", "156.25"
        ].join(" ")
      }

      let(:summary_row){
        [
          "TOTAL", "180.0", "7.54", "187.54"
        ].join(" ")
      }

      it 'should list all the tax rates' do
        visit_report
        run_report

        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).not_to have_content(admin_state_tax1)
        expect(table).not_to have_content(admin_country_tax1)
        expect(table).to have_content(transport_state_tax1)
        expect(table).to have_content(transport_country_tax1)
        expect(table).not_to have_content(packing_state_tax1)
        expect(table).not_to have_content(packing_country_tax1)

        expect(table).not_to have_content(admin_state_tax2)
        expect(table).to have_content(transport_state_tax2)
        expect(table).not_to have_content(packing_state_tax2)

        expect(table).to have_content(supplier1_cost_of_produce_line_items)
        expect(table).to have_content(summary_row)
      end
    end

    context "included tax" do
      let(:included_in_price) { true }

      let(:admin_state_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin",
          "Distributor", "tax_category", "State", "0.015", "19.21", "0.3", "19.51"
        ].join(" ")
      }
      let(:admin_country_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin",
          "Distributor", "tax_category", "Country", "0.025", "38.33", "0.98", "39.31"
        ].join(" ")
      }
      let(:transport_state_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport",
          "Supplier1", "tax_category", "State", "0.015", "14.41", "0.22", "14.63"
        ].join(" ")
      }
      let(:transport_country_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport",
          "Supplier1", "tax_category", "Country", "0.025", "28.75", "0.74", "29.49"
        ].join(" ")
      }
      let(:packing_state_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing",
          "Distributor", "tax_category", "State", "0.015", "9.61", "0.15", "9.76"
        ].join(" ")
      }
      let(:packing_country_tax1){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing",
          "Distributor", "tax_category", "Country", "0.025", "19.17", "0.48", "19.65"
        ].join(" ")
      }

      let(:admin_state_tax2){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Adminstration", "admin",
          "Distributor", "tax_category", "Another State Tax", "0.02", "19.12", "0.39", "19.51"
        ].join(" ")
      }
      let(:transport_state_tax2){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Transport", "transport",
          "Supplier1", "tax_category", "Another State Tax", "0.02", "14.34", "0.29", "14.63"
        ].join(" ")
      }
      let(:packing_state_tax2){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Packing", "packing",
          "Distributor", "tax_category", "Another State Tax", "0.02", "9.56", "0.2", "9.76"
        ].join(" ")
      }

      let(:supplier1_cost_of_produce_line_items){
        [
          "Distributor", "Supplier1", "Yes", "oc1", "Cost of produce line items",
          "Supplier1", "143.88", "6.12", "150.0"
        ].join(" ")
      }

      let(:summary_row){
        [
          "TOTAL", "172.63", "7.37", "180.0"
        ].join(" ")
      }

      it 'should list all the tax rates' do
        visit_report
        run_report

        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).not_to have_content(admin_state_tax1)
        expect(table).not_to have_content(admin_country_tax1)
        expect(table).to have_content(transport_state_tax1)
        expect(table).to have_content(transport_country_tax1)
        expect(table).not_to have_content(packing_state_tax1)
        expect(table).not_to have_content(packing_country_tax1)

        expect(table).not_to have_content(admin_state_tax2)
        expect(table).to have_content(transport_state_tax2)
        expect(table).not_to have_content(packing_state_tax2)

        expect(table).to have_content(supplier1_cost_of_produce_line_items)
        expect(table).to have_content(summary_row)
      end
    end
  end

  def visit_report
    login_as distributor_owner
    visit admin_report_path(
      report_type: :enterprise_fee_summary,
      report_subtype: :enterprise_fees_with_tax_report_by_producer
    )
  end
end
