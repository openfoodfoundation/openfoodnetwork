# frozen_string_literal: true

require 'system_helper'

describe '
  As an Administrator
  I want to be able to manage orders in bulk
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  context "listing orders" do
    before :each do
      login_as_admin
    end
    context "when no orders exist" do
      before :each do
        visit_bulk_order_management
      end
      it "displays a message when number of line items is zero" do
        expect(page).to have_text 'No orders found.'
      end
    end

    context "displaying the list of line items" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.parse('2022-05-05 15:30:45'))
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.parse('2022-04-26 15:10:45'))
      }
      let!(:o21) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.parse('2022-08-04 09:10:45'))
      }
      let!(:o22) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.parse('2022-06-07 09:10:45'))
      }
      let!(:o3) { create(:order_with_distributor, state: 'address', completed_at: nil ) }
      let!(:o4) { create(:order_with_distributor, state: 'complete', completed_at: Time.zone.now ) }
      let!(:o5) { create(:order_with_distributor, state: 'complete', completed_at: Time.zone.now ) }
      let!(:li1) { create(:line_item_with_shipment, order: o1) }
      let!(:li2) { create(:line_item_with_shipment, order: o2) }
      let!(:li21) { create(:line_item_with_shipment, order: o21) }
      let!(:li22) { create(:line_item_with_shipment, order: o22) }
      let!(:li3) { create(:line_item, order: o3 ) }
      let!(:li4) { create(:line_item_with_shipment, order: o4) }
      let!(:li5) { create(:line_item_with_shipment, order: o5) }

      before :each do
        visit_bulk_order_management
      end

      it "displays a list of line items" do
        expect(page).to have_selector "tr#li_#{li1.id}"
        expect(page).to have_selector "tr#li_#{li2.id}"
        expect(page).to have_no_selector "tr#li_#{li3.id}"
      end

      it "displays only line items that are not shipped" do
        expect(page).to have_selector "tr#li_#{li1.id}"
        expect(page).to have_selector "tr#li_#{li2.id}"
        expect(page).to have_no_selector "tr#li_#{li4.id}"
        expect(page).to have_no_selector "tr#li_#{li5.id}"
      end

      it "orders by completion date" do
        find("a", text: 'COMPLETED AT').click # sets ascending ordering
        expect(page).to have_content(
          /#{li2.product.name}.*#{li1.product.name}.*#{li22.product.name}.*#{li21.product.name}/m
        )
        find("a", text: 'COMPLETED AT').click # sets descending ordering
        expect(page).to have_content(
          /#{li21.product.name}.*#{li22.product.name}.*#{li1.product.name}.*#{li2.product.name}/m
        )
      end
    end

    context "pagination" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.yesterday )
      }
      let!(:o3) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.yesterday - 1.day )
      }
      let!(:product) {
        create(:simple_product)
      }
      let!(:var1) {
        create(:variant, product_id: product.id, display_name: "Little Fish")
      }
      let!(:var2) {
        create(:variant, product_id: product.id, display_name: "Big Fish")
      }

      before do
        10.times {
          create(:line_item_with_shipment, variant: var1, order: o2)
        }
        5.times {
          create(:line_item_with_shipment, variant: var2, order: o1)
        }
        5.times {
          create(:line_item_with_shipment, variant: var1, order: o3)
        }
      end

      it "splits results according to line items from orders" do
        visit_bulk_order_management

        expect(page).to have_select2 "autogen4", selected: "15 per page" # should be default option
        expect(page).to have_content "20 Results found. Viewing 1 to 15."
        expect(page).to have_button("« First", disabled: true)
        expect(page).to have_button("Previous", disabled: true)
        expect(page).to have_button("1", disabled: true)
        expect(page).to have_button("2", disabled: false)
        expect(page).to have_button("Next", disabled: false)
        expect(page).to have_button("Last »", disabled: false)
        within "tbody" do
          expect(page).to have_css("tr", count: 15) # verifies the remaining 15 line items are shown
        end
        click_button "2" # switches to the second results page
        within "tbody" do
          expect(page).to have_css("tr", count: 5) # verifies the remaining 5 line items are shown
        end
        click_button "1" # switches to the first results page
        select2_select "50 per page", from: "autogen4" # should display all 20 line items
        expect(page).to have_content "20 Results found. Viewing 1 to 20."
        expect(page).to have_button("« First", disabled: true)
        expect(page).to have_button("Previous", disabled: true)
        expect(page).to have_button("1", disabled: true)
        expect(page).to_not have_button("2")
        expect(page).to have_button("Next", disabled: true)
        expect(page).to have_button("Last »", disabled: true)
        select2_select "100 per page", from: "autogen4" # should display all 20 line items
        expect(page).to have_content "20 Results found. Viewing 1 to 20."
      end

      it "clicking the product variant" do
        visit_bulk_order_management
        expect(page).to have_content "Little Fish", count: 10
        expect(page).to have_content "Big Fish", count: 5
        click_on("Little Fish") # opens BOM box
        within "#listing_orders" do
          expect(page).to have_content "Little Fish", count: 15
          expect(page).not_to have_content "Big Fish"
        end
        find("a", text: "Clear").click # closes BOM box
        expect(page).to have_content "Little Fish", count: 10
        expect(page).to have_content "Big Fish", count: 5
      end
    end

    context "searching" do
      let!(:a1) { create(:address, phone: "1234567890", firstname: "Willy", lastname: "Wonka") }
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now, bill_address: a1)
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:s1) { create(:supplier_enterprise) }
      let!(:s2) { create(:supplier_enterprise) }
      let!(:li1) {
        create(:line_item_with_shipment, order: o1, product: create(:product, supplier: s1))
      }
      let!(:li2) {
        create(:line_item_with_shipment, order: o2, product: create(:product, supplier: s2))
      }
      let!(:li3) {
        create(:line_item_with_shipment, order: o2, product: create(:product, supplier: s2))
      }

      before :each do
        visit_bulk_order_management
      end

      it "by product name" do
        fill_in "quick_filter", with: li1.product.name
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end

      it "by supplier name" do
        fill_in "quick_filter", with: li1.product.supplier.name
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end

      it "by email" do
        fill_in "quick_filter", with: o1.email
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end

      it "by order number" do
        fill_in "quick_filter", with: o1.number
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end

      it "by phone number" do
        fill_in "quick_filter", with: o1.bill_address.phone
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end

      it "by distributor name" do
        fill_in "quick_filter", with: o1.distributor.name
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end

      it "by customer name" do
        fill_in "quick_filter", with: o1.bill_address.firstname
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]

        fill_in "quick_filter", with: o1.bill_address.lastname
        page.find('.filter-actions .button.icon-search').click

        expect_line_items_results [li1], [li2, li3]
      end
    end

    context "displaying individual columns" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now,
                                        bill_address: create(:address) )
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now,
                                        bill_address: nil )
      }
      let!(:li1) { create(:line_item_with_shipment, order: o1) }
      let!(:li2) {
        create(:line_item_with_shipment, order: o2, product: create(:product) )
      }

      before :each do
        visit_bulk_order_management
      end

      it "displays a column for user's full name" do
        expect(page).to have_selector "th.full_name", text: "NAME"
        expect(page)
          .to have_selector "td.full_name",
                            text: "#{o1.bill_address.last_name}, #{o1.bill_address.first_name}"
        expect(page).to have_selector "td.full_name", text: ""
      end

      it "displays a column for order date" do
        expect(page).to have_selector "th.date",
                                      text: 'Completed at'.upcase
        expect(page).to have_selector "td.date", text: o1.completed_at.strftime('%B %d, %Y')
        expect(page).to have_selector "td.date", text: o2.completed_at.strftime('%B %d, %Y')
      end

      it "displays a column for producer" do
        expect(page).to have_selector "th.producer", text: "PRODUCER"
        expect(page).to have_selector "td.producer", text: li1.product.supplier.name
        expect(page).to have_selector "td.producer", text: li2.product.supplier.name
      end

      it "displays a column for variant description, which shows only product name " \
         "when options text is blank" do
        expect(page).to have_selector "th.variant", text: "PRODUCT: UNIT"
        expect(page).to have_selector "td.variant", text: li1.product.name
        expect(page).to have_selector "td.variant",
                                      text: "#{li2.product.name}: #{li2.variant.options_text}"
      end

      it "displays a field for quantity" do
        expect(page).to have_selector "th.quantity", text: "QUANTITY"
        expect(page).to have_field "quantity", with: li1.quantity.to_s
        expect(page).to have_field "quantity", with: li2.quantity.to_s
      end

      it "displays a column for max quantity" do
        expect(page).to have_selector "th.max", text: "MAX"
        expect(page).to have_selector "td.max", text: li1.max_quantity.to_s
        expect(page).to have_selector "td.max", text: li2.max_quantity.to_s
      end
    end

    describe "sorting of line items" do
      let!(:o1) do
        create(
          :order_with_distributor,
          bill_address: create(:address, first_name: 'Bob', last_name: 'Taylor'),
          state: 'complete',
          shipment_state: 'ready',
          completed_at: Time.zone.now
        )
      end

      let!(:o2) do
        create(
          :order_with_distributor,
          bill_address: create(:address, first_name: 'Mary', last_name: 'Smith'),
          state: 'complete',
          shipment_state: 'ready',
          completed_at: Time.zone.now
        )
      end

      let!(:o3) do
        create(
          :order_with_distributor,
          bill_address: create(:address, first_name: 'Bill', last_name: 'Taylor'),
          state: 'complete',
          shipment_state: 'ready',
          completed_at: Time.zone.now
        )
      end

      let!(:li1) { create(:line_item_with_shipment, order: o1) }
      let!(:li2) { create(:line_item_with_shipment, order: o2) }
      let!(:li3) { create(:line_item_with_shipment, order: o3) }

      before :each do
        visit_bulk_order_management
      end

      it "sorts by customer last name when the customer name header is clicked" do
        within "#listing_orders thead" do
          click_on "Name"
        end

        expect(page).to have_selector("#listing_orders .line_item:nth-child(1) .full_name",
                                      text: "Smith, Mary")
        expect(page).to have_selector("#listing_orders .line_item:nth-child(2) .full_name",
                                      text: "Taylor, Bill")
        expect(page).to have_selector("#listing_orders .line_item:nth-child(3) .full_name",
                                      text: "Taylor, Bob")
      end

      it "sorts by customer last name in reverse when the customer name header is clicked twice" do
        within "#listing_orders thead" do
          click_on "Name"
          click_on "Name"
        end

        expect(page).to have_selector("#listing_orders .line_item:nth-child(1) .full_name",
                                      text: "Taylor, Bob")
        expect(page).to have_selector("#listing_orders .line_item:nth-child(2) .full_name",
                                      text: "Taylor, Bill")
        expect(page).to have_selector("#listing_orders .line_item:nth-child(3) .full_name",
                                      text: "Smith, Mary")
      end
    end
  end

  context "altering line item properties" do
    before :each do
      login_as_admin
    end

    context "tracking changes" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:li1) { create(:line_item_with_shipment, order: o1, quantity: 5 ) }

      before :each do
        visit_bulk_order_management
      end

      it "adds the class 'ng-dirty' to input elements when value is altered" do
        expect(page).to have_no_css "input[name='quantity'].ng-dirty"
        fill_in "quantity", with: 2
        expect(page).to have_css "input[name='quantity'].ng-dirty"
      end
    end

    context "submitting data to the server" do
      let!(:order) { create(:completed_order_with_fees) }

      before :each do
        order.line_items.second.destroy # we keep only one line item for this test
        visit_bulk_order_management
      end

      context "when acceptable data is sent to the server" do
        it "displays an update button which submits pending changes" do
          expect(page).to have_no_selector "#save-bar"
          fill_in "quantity", with: 2
          expect(page).to have_selector "input[name='quantity'].ng-dirty"
          expect(page).to have_selector "#save-bar", text: "You have unsaved changes"
          click_button "Save Changes"
          expect(page).to have_selector "#save-bar", text: "All changes saved"
          expect(page).to have_no_selector "input[name='quantity'].ng-dirty"
        end
      end

      context "when unacceptable data is sent to the server" do
        it "displays an update button which submits pending changes" do
          expect(page).to have_no_selector "#save-bar"
          line_item = order.line_items.first
          fill_in "quantity", with: line_item.variant.on_hand + line_item.quantity + 10
          expect(page).to have_selector "input[name='quantity'].ng-dirty"
          expect(page).to have_selector "#save-bar", text: "You have unsaved changes"
          click_button "Save Changes"
          expect(page).to have_selector "#save-bar", text: "Fields with red borders contain errors."
          expect(page).to have_selector "input[name='quantity'].ng-dirty.update-error"
          expect(page).to have_content "is out of stock"
        end
      end
    end
  end

  context "using page controls" do
    before :each do
      login_as_admin
    end

    let!(:p1) {
      create(:product, group_buy: true, group_buy_unit_size: 5000,
                       variant_unit: "weight", variants: [create(:variant, unit_value: 1000)] )
    }
    let!(:v1) { p1.variants.first }
    let!(:o1) {
      create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                      completed_at: Time.zone.now )
    }
    let!(:li1) {
      create(:line_item_with_shipment, order: o1, variant: v1, quantity: 5,
                                       final_weight_volume: 1000, price: 10.00 )
    }

    before :each do
      v1.update_attribute(:on_hand, 100)
      visit_bulk_order_management
    end

    context "modifying the weight/volume of a line item" do
      before do
        toggle_columns "Weight/Volume", "Price"
      end
      it "price is altered" do
        within "tr#li_#{li1.id}" do
          expect(page).to have_field "price", with: "50.00"
          fill_in "final_weight_volume", with: 2000
          expect(page).to have_field "price", with: "100.00"
        end
        click_button "Save Changes"
        expect(page).to have_content "All changes saved"
        li1.reload
        expect(li1.final_weight_volume).to eq 2000
        expect(li1.price).to eq 20.00
      end
    end

    context "modifying the quantity of a line item" do
      before do
        toggle_columns "Price"
      end
      it "price is altered" do
        within "tr#li_#{li1.id}" do
          expect(page).to have_field "price", with: format('%.2f', li1.price * 5).to_s
          fill_in "quantity", with: 6
          expect(page).to have_field "price", with: format('%.2f', li1.price * 6).to_s
        end
      end
    end

    context "modifying the quantity of a line item" do
      before do
        toggle_columns "Weight/Volume"
      end
      it "weight/volume is altered" do
        within "tr#li_#{li1.id}" do
          expect(page).to have_field "final_weight_volume", with: li1.final_weight_volume.round.to_s
          fill_in "quantity", with: 6
          expect(page).to have_field "final_weight_volume",
                                     with: ((li1.final_weight_volume * 6) / 5).round.to_s
        end
      end
    end

    context "using column display toggle" do
      it "displays the default selected columns" do
        expect(page).to have_selector "th", text: "NAME"
        expect(page).to have_selector "th",
                                      text: 'Completed at'.upcase
        expect(page).to have_selector "th", text: "PRODUCER"
        expect(page).to have_selector "th", text: "PRODUCT: UNIT"
        expect(page).to have_selector "th", text: "QUANTITY"
        expect(page).to have_selector "th", text: "MAX"
      end

      context "hiding a column, by de-selecting it from the drop-down" do
        before do
          toggle_columns "Producer"
        end

        it "shows all default columns, except the de-selected column" do
          expect(page).to have_no_selector "th", text: "PRODUCER"
          expect(page).to have_selector "th", text: "NAME"
          expect(page).to have_selector "th",
                                        text: 'Completed at'.upcase
          expect(page).to have_selector "th", text: "PRODUCT: UNIT"
          expect(page).to have_selector "th", text: "QUANTITY"
          expect(page).to have_selector "th", text: "MAX"
        end
      end
    end

    context "using drop down seletors" do
      context "supplier filter" do
        let!(:s1) { create(:supplier_enterprise) }
        let!(:s2) { create(:supplier_enterprise) }
        let!(:o1) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now,
                                          order_cycle: create(:simple_order_cycle) )
        }
        let!(:li1) {
          create(:line_item_with_shipment, order: o1, product: create(:product, supplier: s1) )
        }
        let!(:li2) {
          create(:line_item_with_shipment, order: o1, product: create(:product, supplier: s2) )
        }

        before :each do
          visit_bulk_order_management
        end

        it "displays select box for producers, which filters line items by the selected supplier" do
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
          open_select2 "#s2id_supplier_filter"
          expect(page).to have_selector "div.select2-drop-active ul.select2-results li", text: "All"
          Enterprise.is_primary_producer.map(&:name).each do |sn|
            expect(page).to have_selector "div.select2-drop-active ul.select2-results li", text: sn
          end
          close_select2
          select2_select s1.name, from: "supplier_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
        end

        it "displays all line items when 'All' is selected from supplier filter" do
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
          select2_select s1.name, from: "supplier_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          select2_select "All", from: "supplier_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
        end
      end

      context "distributor filter" do
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:o1) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now, distributor: d1,
                                          order_cycle: create(:simple_order_cycle) )
        }
        let!(:o2) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now, distributor: d2,
                                          order_cycle: create(:simple_order_cycle) )
        }
        let!(:li1) { create(:line_item_with_shipment, order: o1 ) }
        let!(:li2) { create(:line_item_with_shipment, order: o2 ) }

        before :each do
          visit_bulk_order_management
        end

        it "displays a select box for distributors, which filters line items " \
           "by the selected distributor", retry: 3 do
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
          find("#s2id_distributor_filter .select2-chosen").click
          expect(page).to have_selector "div.select2-drop-active ul.select2-results li", text: "All"
          Enterprise.is_distributor.map(&:name).each do |dn|
            expect(page).to have_selector "div.select2-drop-active ul.select2-results li", text: dn
          end
          find(".select2-result-label", text: d1.name.to_s).click
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
        end

        it "displays all line items when 'All' is selected from distributor filter", retry: 3 do
          # displays orders from one enterprise only
          expect(page).to have_selector "tr#li_#{li2.id}"
          find("#s2id_distributor_filter .select2-chosen").click
          find(".select2-result-label", text: d1.name.to_s).click
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          # displays orders from all enterprises
          find("#s2id_distributor_filter .select2-chosen").click
          find(".select2-result-label", text: "All").click
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
        end
      end

      context "order_cycle filter" do
        let!(:distributor) { create(:distributor_enterprise) }
        let!(:oc1) { create(:simple_order_cycle, distributors: [distributor]) }
        let!(:oc2) { create(:simple_order_cycle, distributors: [distributor]) }
        let!(:oc3) { create(:simple_order_cycle, distributors: [distributor]) }
        let!(:o1) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now,
                                          order_cycle: oc1 )
        }
        let!(:o2) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now,
                                          order_cycle: oc2 )
        }
        let!(:o3) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: 1.week.from_now,
                                          order_cycle: oc3 )
        }
        let!(:o4) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: 2.weeks.from_now,
                                          order_cycle: oc3 )
        }
        let!(:li1) { create(:line_item_with_shipment, order: o1 ) }
        let!(:li2) { create(:line_item_with_shipment, order: o2 ) }
        let!(:li3) { create(:line_item_with_shipment, order: o3 ) }
        let!(:li4) { create(:line_item_with_shipment, order: o4 ) }

        before do
          oc3.update!(orders_close_at: 2.weeks.from_now)
          oc3.update!(orders_open_at: 1.week.from_now)
          visit_bulk_order_management
        end

        it "displays a select box for order cycles, which filters line items " \
           "by the selected order cycle", retry: 3 do
          displays_default_orders
          expect(page).to have_select2 'order_cycle_filter',
                                       with_options: OrderCycle.pluck(:name).unshift("All")
          select2_select oc1.name, from: "order_cycle_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_no_selector "#loading i"
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
        end

        it "displays all line items when 'All' is selected from order_cycle filter", retry: 3 do
          displays_default_orders
          select2_select oc1.name, from: "order_cycle_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          select2_select "All", from: "order_cycle_filter"
          page.find('.filter-actions .button.icon-search').click
          displays_default_orders
        end
      end

      context "combination of filters" do
        let!(:s1) { create(:supplier_enterprise) }
        let!(:s2) { create(:supplier_enterprise) }
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:oc1) { create(:simple_order_cycle, suppliers: [s1], distributors: [d1] ) }
        let!(:oc2) { create(:simple_order_cycle, suppliers: [s2], distributors: [d2] ) }
        let!(:p1) { create(:product, supplier: s1) }
        let!(:p2) { create(:product, supplier: s2) }
        let!(:o1) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now, distributor: d1,
                                          order_cycle: oc1 )
        }
        let!(:o2) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now, distributor: d2,
                                          order_cycle: oc2 )
        }
        let!(:li1) { create(:line_item_with_shipment, order: o1, product: p1 ) }
        let!(:li2) { create(:line_item_with_shipment, order: o2, product: p2 ) }

        before :each do
          visit_bulk_order_management
        end

        it "allows filters to be used in combination", retry: 3 do
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
          click_on_select2 oc1.name, from: "order_cycle_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          click_on_select2 d1.name, from: "distributor_filter"
          click_on_select2 s1.name, from: "supplier_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          click_on_select2 d2.name, from: "distributor_filter"
          click_on_select2 s2.name, from: "supplier_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_no_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          click_on_select2 oc2.name, from: "order_cycle_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_no_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
        end

        it "displays a 'Clear All' button which sets all select filters to 'All'", retry: 3 do
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
          click_on_select2 oc1.name, from: "order_cycle_filter"
          click_on_select2 d1.name, from: "distributor_filter"
          click_on_select2 s1.name, from: "supplier_filter"
          page.find('.filter-actions .button.icon-search').click
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          page.find('.filter-actions #clear_filters_button').click
          expect(page).to have_selector "div#s2id_order_cycle_filter a.select2-choice", text: "All"
          expect(page).to have_selector "div#s2id_supplier_filter a.select2-choice", text: "All"
          expect(page).to have_selector "div#s2id_distributor_filter a.select2-choice", text: "All"
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
        end
      end
    end

    context "using date restriction controls" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.today - 7.days - 1.second)
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.today - 6.days)
      }
      let!(:o3) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now.end_of_day)
      }
      let!(:o4) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now.end_of_day + 1.day)
      }
      let!(:li1) { create(:line_item_with_shipment, order: o1, quantity: 1 ) }
      let!(:li2) { create(:line_item_with_shipment, order: o2, quantity: 2 ) }
      let!(:li3) { create(:line_item_with_shipment, order: o3, quantity: 3 ) }
      let!(:li4) { create(:line_item_with_shipment, order: o4, quantity: 4 ) }
      let(:today) { Time.zone.today }

      before :each do
        visit_bulk_order_management
      end

      it "loads all line items because no date restriction on first load" do
        expect(page).to have_selector "tr#li_#{li1.id}"
        expect(page).to have_selector "tr#li_#{li2.id}"
        expect(page).to have_selector "tr#li_#{li3.id}"
        expect(page).to have_selector "tr#li_#{li4.id}"
      end

      it "displays only line items whose orders meet the date restriction criteria, when changed",
         retry: 3 do
        from = today - 8.days
        to = today + 1.day

        find("input.datepicker").click
        select_dates_from_daterangepicker(from, today)
        page.find('.filter-actions .button.icon-search').click

        expect(page).to have_selector "tr#li_#{li1.id}"
        expect(page).to have_selector "tr#li_#{li2.id}"
        expect(page).to have_selector "tr#li_#{li3.id}"
        expect(page).to have_no_selector "tr#li_#{li4.id}"

        find("input.datepicker").click
        select_dates_from_daterangepicker(from, to)
        page.find('.filter-actions .button.icon-search').click

        expect(page).to have_selector "tr#li_#{li1.id}"
        expect(page).to have_selector "tr#li_#{li2.id}"
        expect(page).to have_selector "tr#li_#{li3.id}"
        expect(page).to have_selector "tr#li_#{li4.id}"
      end

      context "when the form is dirty" do
        before do
          within("tr#li_#{li2.id} td.quantity") do
            page.fill_in "quantity", with: (li2.quantity + 1).to_s
          end
        end

        it "shows a dialog and ignores changes when confirm dialog is accepted" do
          accept_confirm "Unsaved changes exist and will be lost if you continue." do
            find("input.datepicker").click
            select_dates_from_daterangepicker(today - 9.days, today)
            page.find('.filter-actions .button.icon-search').click
          end
          # daterange picker should have changed
          expect(find("input.datepicker").value)
            .to eq "#{today.prev_day(9).strftime('%F')} to #{today.strftime('%F')}"
          expect(page).to have_no_selector "#save-bar"
          within("tr#li_#{li2.id} td.quantity") do
            expect(page).to have_no_selector "input[name=quantity].ng-dirty"
          end
        end

        it "shows a dialog and keeps changes when confirm dialog is rejected" do
          previousdaterangestring = find("input.datepicker").value
          dismiss_confirm "Unsaved changes exist and will be lost if you continue." do
            find("input.datepicker").click
            select_dates_from_daterangepicker(today - 9.days, today)
            page.find('.filter-actions .button.icon-search').click
          end
          expect(page).to have_selector "#save-bar"
          within("tr#li_#{li2.id} td.quantity") do
            expect(page).to have_selector "input[name=quantity].ng-dirty"
          end
        end
      end
    end

    context "bulk action controls" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:li1) { create(:line_item_with_shipment, order: o1 ) }
      let!(:li11) { create(:line_item_with_shipment, order: o1 ) }
      let!(:li2) { create(:line_item_with_shipment, order: o2 ) }

      before :each do
        visit_bulk_order_management
      end

      it "displays a checkbox for each line item in the list" do
        expect(page).to have_selector "tr#li_#{li1.id} input[type='checkbox'][name='bulk']"
        expect(page).to have_selector "tr#li_#{li2.id} input[type='checkbox'][name='bulk']"
      end

      it "displays a checkbox to which toggles the 'checked' state of all checkboxes" do
        check "toggle_bulk"
        page.all("input[type='checkbox'][name='bulk']").each{ |checkbox|
          expect(checkbox.checked?).to be true
        }
        uncheck "toggle_bulk"
        page.all("input[type='checkbox'][name='bulk']").each{ |checkbox|
          expect(checkbox.checked?).to be false
        }
      end

      it "displays a bulk action select box with a list of actions" do
        list_of_actions = ['Delete Selected']
        find("div#bulk-actions-dropdown").click
        within("div#bulk-actions-dropdown") do
          list_of_actions.each { |action_name|
            expect(page).to have_selector "div.menu_item", text: action_name
          }
        end
      end

      context "performing actions" do
        context "deletes selected items" do
          it "displays a confirmation dialog when deleting one or more items " \
             "leads to order cancelation" do
            expect(page).to have_selector "tr#li_#{li1.id}"
            expect(page).to have_selector "tr#li_#{li11.id}"
            within("tr#li_#{li1.id} td.bulk") do
              check "bulk"
            end
            within("tr#li_#{li11.id} td.bulk") do
              check "bulk"
            end

            find("div#bulk-actions-dropdown").click
            find("div#bulk-actions-dropdown div.menu_item", text: "Delete Selected" ).click

            expect(page).to have_content "This operation will result in one or more empty " \
                                         "orders, which will be cancelled. Do you wish to proceed?"

            expect do
              within(".modal") do
                check("send_cancellation_email")
                click_on("OK")
              end
              # order 1 should be canceled
              expect(page).to have_no_selector "tr#li_#{li1.id}"
              expect(page).to have_no_selector "tr#li_#{li11.id}"
              expect(o1.reload.state).to eq("canceled")
              # order 2 should not be canceled
              expect(page).to have_selector "tr#li_#{li2.id}"
              expect(o2.reload.state).to eq("complete")
            end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
          end

          it "deletes one line item should show modal confirmation about this line item deletion " \
             "and not about order cancelation" do
            expect(page).to have_selector "tr#li_#{li1.id}"
            within("tr#li_#{li1.id} td.bulk") do
              check "bulk"
            end

            find("div#bulk-actions-dropdown").click
            find("div#bulk-actions-dropdown div.menu_item", text: "Delete Selected" ).click

            within ".modal" do
              expect(page).to have_content "This will delete one line item from the order. " \
                                           "Are you sure you want to proceed?"
              click_on "OK"
            end

            expect(page).to have_no_selector ".modal"
            expect(page).to have_no_selector "tr#li_#{li1.id}"
            expect(page).to have_selector "tr#li_#{li11.id}"
            expect(o1.reload.state).to eq("complete")
          end
        end
      end
    end

    context "using action buttons" do
      context "using edit buttons" do
        let(:address) { create(:address) }
        let!(:o1) {
          create(:order_with_distributor, ship_address: address, state: 'complete',
                                          shipment_state: 'ready', completed_at: Time.zone.now )
        }
        let!(:o2) {
          create(:order_with_distributor, ship_address: address, state: 'complete',
                                          shipment_state: 'ready', completed_at: Time.zone.now )
        }
        let!(:li1) { create(:line_item_with_shipment, order: o1 ) }
        let!(:li2) { create(:line_item_with_shipment, order: o2 ) }

        before :each do
          o1.update_totals_and_states
          o2.update_totals_and_states

          visit_bulk_order_management
        end

        it "shows an edit button for line_items, which takes the user " \
           "to the standard edit page for the order" do
          expect(page).to have_selector "a.edit-order", count: 2

          # Shows a confirm dialog when unsaved changes exist
          page.driver
            .dismiss_modal :confirm,
                           text: "Unsaved changes exist and will be lost if you continue." do
            within "tr#li_#{li1.id}" do
              fill_in "quantity", with: (li1.quantity + 1)
              find("a.edit-order").click
            end
          end

          # So we save the changes
          expect(URI.parse(current_url).path).to eq "/admin/orders/bulk_management"
          click_button "Save Changes"
          expect(page).to have_selector "#save-bar", text: "All changes saved"

          # And try again
          within "tr#li_#{li1.id}" do
            find("a.edit-order").click
          end

          expect(URI.parse(current_url).path).to eq "/admin/orders/#{o1.number}/edit"
        end
      end

      context "using delete buttons" do
        let!(:o1) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now )
        }
        let!(:o2) {
          create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                          completed_at: Time.zone.now )
        }
        let!(:li1) { create(:line_item_with_shipment, order: o1 ) }
        let!(:li2) { create(:line_item_with_shipment, order: o2 ) }

        context "when deleting a line item of an order that have more than one line item" do
          let!(:li12) { create(:line_item_with_shipment, order: o1 ) }

          it "removes a line item when the relevant delete button is clicked" do
            visit_bulk_order_management

            expect(page).to have_selector "a.delete-line-item", count: 3
            accept_alert do
              find("tr#li_#{li1.id} a.delete-line-item").click
            end
            expect(page).to have_selector "a.delete-line-item", count: 2
          end
        end

        context "when deleting the last item of an order, " \
                "it shows a modal about order cancellation" do
          before :each do
            visit_bulk_order_management
            expect(page).to have_selector "a.delete-line-item", count: 2
            find("tr#li_#{li2.id} a.delete-line-item").click
            expect(page)
              .to have_content "This operation will result in one or more empty orders, " \
                               "which will be cancelled. Do you wish to proceed?"
            expect(page).to have_checked_field "Restock Items: return all items to stock"
          end

          it "the user can cancel : no line item is deleted" do
            within(".modal") do
              click_on("Cancel")
            end
            expect(o2.reload.line_items.length).to eq(1)
            expect(page).to have_selector "a.delete-line-item", count: 2
          end

          it "the user can confirm : line item is then deleted and order is canceled" do
            expect_any_instance_of(Spree::StockLocation).to receive(:restock).at_least(1).times
            expect do
              within(".modal") do
                uncheck("send_cancellation_email")
                click_on("OK")
              end
              expect(page).to have_selector "a.delete-line-item", count: 1
              expect(o2.reload.state).to eq("canceled")
            end.to_not have_enqueued_mail(Spree::OrderMailer, :cancel_email)
          end

          it "the user can confirm + wants to send email confirmation : line item is " \
             "then deleted, order is canceled and email is sent" do
            expect_any_instance_of(Spree::StockLocation).to receive(:restock).at_least(1).times
            expect do
              within(".modal") do
                check("send_cancellation_email")
                click_on("OK")
              end
              expect(page).to have_selector "a.delete-line-item", count: 1
              expect(o2.reload.state).to eq("canceled")
            end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
          end

          it "the user can confirm + uncheck the restock option: line item is then deleted and " \
             "order is canceled without retocking" do
            expect_any_instance_of(Spree::StockLocation).to_not receive(:restock)
            expect do
              within(".modal") do
                uncheck("Restock Items: return all items to stock")
                click_on("OK")
              end
              expect(page).to have_selector "a.delete-line-item", count: 1
              expect(o2.reload.state).to eq("canceled")
            end.to have_enqueued_mail(Spree::OrderMailer, :cancel_email)
          end
        end
      end
    end

    context "clicking the link on variant name" do
      let!(:o1) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:o2) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:li1) { create(:line_item_with_shipment, order: o1 ) }
      let!(:li2) { create(:line_item_with_shipment, order: o2 ) }
      let!(:p3) {
        create(:product, group_buy: true, group_buy_unit_size: 5000,
                         variant_unit: "weight", variants: [create(:variant, unit_value: 1000)] )
      }
      let!(:v3) { p3.variants.first }
      let!(:o3) {
        create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                        completed_at: Time.zone.now )
      }
      let!(:li3) {
        create(:line_item_with_shipment, order: o3, variant: v3, quantity: 3, max_quantity: 6 )
      }
      let!(:li4) {
        create(:line_item_with_shipment, order: o2, variant: v3, quantity: 1, max_quantity: 3 )
      }

      before :each do
        visit_bulk_order_management
        within "tr#li_#{li3.id}" do
          find("a", text: "#{li3.product.name}: #{li3.variant.options_text}").click
        end
      end

      shared_examples "display only group by information for selected variant" do
        it "displays group buy calc box" do
          expect(page).to have_selector "div#group_buy_calculation"

          within "div#group_buy_calculation" do
            expect(page).to have_text "Group Buy Unit Size"
            expect(page).to have_text "5000 g"
            expect(page).to have_text "Total Quantity Ordered"
            expect(page).to have_text "4000 g"
            expect(page).to have_text "Max Quantity Ordered"
            expect(page).to have_text "9000 g"
            expect(page).to have_text "Current Fulfilled Units"
            expect(page).to have_text "0.8"
            expect(page).to have_text "Max Fulfilled Units"
            expect(page).to have_text "1.8"
            expect(page).to have_selector "div.shared_resource"
            within "div.shared_resource" do
              expect(page).to have_selector "span", text: "Shared Resource?"
              expect(page).to have_selector "input#shared_resource"
            end
          end
        end

        it "all line items of the same variant" do
          expect(page).to have_no_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          expect(page).to have_selector "tr#li_#{li3.id}"
          expect(page).to have_selector "tr#li_#{li4.id}"
          expect(page).to have_css("table#listing_orders tbody tr", count: 2)
        end
      end

      it_behaves_like "display only group by information for selected variant"

      context "clicking 'Clear' in group buy box" do
        before :each do
          find("a", text: "Clear").click
        end

        it "shows all products and clears group buy box" do
          expect(page).to have_no_selector "div#group_buy_calculation"
          expect(page).to have_selector "tr#li_#{li1.id}"
          expect(page).to have_selector "tr#li_#{li2.id}"
          expect(page).to have_selector "tr#li_#{li3.id}"
          expect(page).to have_selector "tr#li_#{li4.id}"
        end
      end

      context "when filtering" do
        before do
          fill_in "quick_filter", with: li3.order.email
          page.find('.filter-actions .button.icon-search').click
        end

        it "shows only variant filtering by email" do
          expect(page).to have_no_selector "tr#li_#{li1.id}"
          expect(page).to have_no_selector "tr#li_#{li2.id}"
          expect(page).to have_selector "tr#li_#{li3.id}"
          expect(page).to have_no_selector "tr#li_#{li4.id}"
        end

        context "clicking 'Clear Filters' button" do
          before :each do
            page.find('.filter-actions #clear_filters_button').click
          end

          it_behaves_like "display only group by information for selected variant"

          it "but actually clears the filters" do
            expect(page.find("input[name='quick_filter']").value).to eq("")
          end
        end
      end
    end
  end

  context "as an enterprise manager" do
    let(:s1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:d1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:d2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let!(:o1) {
      create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                      completed_at: Time.zone.now, distributor: d1 )
    }
    let!(:o2) {
      create(:order_with_distributor, state: 'complete', shipment_state: 'ready',
                                      completed_at: Time.zone.now, distributor: d2 )
    }
    let!(:line_item_distributed) {
      create(:line_item_with_shipment, order: o1, product: create(:product, supplier: s1) )
    }
    let!(:line_item_not_distributed) {
      create(:line_item_with_shipment, order: o2, product: create(:product, supplier: s1) )
    }

    before(:each) do
      @enterprise_user = create(:user)
      @enterprise_user.enterprise_roles.build(enterprise: s1).save
      @enterprise_user.enterprise_roles.build(enterprise: d1).save

      login_as @enterprise_user
    end

    it "displays a Bulk Management Tab under the Orders item" do
      visit '/admin/orders'
      expect(page).to have_link "Bulk order management"
      click_link "Bulk order management"
      expect(page).to have_selector "h1.page-title", text: "Bulk Order Management"
    end

    it "shows only line item from orders that I distribute, and not those that I supply" do
      visit_bulk_order_management

      expect(page).to have_selector "tr#li_#{line_item_distributed.id}"
      expect(page).to have_no_selector "tr#li_#{line_item_not_distributed.id}"
    end
  end

  def visit_bulk_order_management
    visit spree.admin_bulk_order_management_path
    expect(page).to have_no_text 'Loading orders'
  end

  def displays_default_orders
    expect(page).to have_selector "tr#li_#{li1.id}"
    expect(page).to have_selector "tr#li_#{li2.id}"
  end

  def expect_line_items_results(line_items, excluded_line_items)
    line_items.each do |li|
      expect(page).to have_selector "tr#li_#{li.id}"
    end
    excluded_line_items.each do |li|
      expect(page).to have_no_selector "tr#li_#{li.id}"
    end
  end
end
