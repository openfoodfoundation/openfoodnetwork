require 'spec_helper'

feature %q{
  As an Administrator
  I want to be able to manage orders in bulk
} , js: true do
  include AuthenticationWorkflow
  include WebHelper

  before :all do
    @default_wait_time = Capybara.default_wait_time
    Capybara.default_wait_time = 5
  end

  after :all do
    Capybara.default_wait_time = @default_wait_time
  end

  context "listing orders" do
    before :each do
      login_to_admin_section
    end

    it "displays a Bulk Management Tab under the Orders item" do
      visit '/admin/orders'

      page.should have_link "Bulk Order Management"
      click_link "Bulk Order Management"
      page.should have_selector "h1.page-title", text: "Bulk Order Management"
    end

    it "displays a message when number of line items is zero" do
      visit '/admin/orders/bulk_management'
      page.should have_text "No matching line items found."
    end

    context "displaying the list of line items" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o3) { FactoryGirl.create(:order, state: 'address', completed_at: nil ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2 ) }
      let!(:li3) { FactoryGirl.create(:line_item, order: o3 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      #it "displays a 'loading' splash for line items" do
      #  page.should have_selector "div.loading", :text => "Loading Line Items..."
      #end

      it "displays a list of line items" do
        page.should have_selector "tr#li_#{li1.id}"
        page.should have_selector "tr#li_#{li2.id}"
        page.should_not have_selector "tr#li_#{li3.id}"
      end
    end

    context "displaying individual columns" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now, bill_address: FactoryGirl.create(:address) ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now, bill_address: nil ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2, product: FactoryGirl.create(:product_with_option_types) ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays a column for user's full name" do
        page.should have_selector "th.full_name", text: "NAME", :visible => true
        page.should have_selector "td.full_name", text: o1.bill_address.full_name, :visible => true
        page.should have_selector "td.full_name", text: "", :visible => true
      end

      it "displays a column for order date" do
        page.should have_selector "th,date", text: "ORDER DATE", :visible => true
        page.should have_selector "td.date", text: o1.completed_at.strftime("%F %T"), :visible => true
        page.should have_selector "td.date", text: o2.completed_at.strftime("%F %T"), :visible => true
      end

      it "displays a column for producer" do
        page.should have_selector "th.producer", text: "PRODUCER", :visible => true
        page.should have_selector "td.producer", text: li1.product.supplier.name, :visible => true
        page.should have_selector "td.producer", text: li2.product.supplier.name, :visible => true
      end

      it "displays a column for variant description, which shows only product name when options text is blank" do
        page.should have_selector "th.variant", text: "PRODUCT: UNIT", :visible => true
        page.should have_selector "td.variant", text: li1.product.name, :visible => true
        page.should have_selector "td.variant", text: (li2.product.name + ": " + li2.variant.options_text), :visible => true
      end

      it "displays a field for quantity" do
        page.should have_selector "th.quantity", text: "QUANTITY", :visible => true
        page.should have_field "quantity", with: li1.quantity.to_s, :visible => true
        page.should have_field "quantity", with: li2.quantity.to_s, :visible => true
      end

      it "displays a column for max quantity" do
        page.should have_selector "th.max", text: "MAX", :visible => true
        page.should have_selector "td.max", text: li1.max_quantity.to_s, :visible => true
        page.should have_selector "td.max", text: li2.max_quantity.to_s, :visible => true
      end
    end
  end

  context "altering line item properties" do
    before :each do
      login_to_admin_section
    end

    context "tracking changes" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1, :quantity => 5 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "adds the class 'update-pending' to input elements when value is altered" do
        page.should_not have_css "input[name='quantity'].update-pending"
        fill_in "quantity", :with => 2
        page.should have_css "input[name='quantity'].update-pending"
      end

      it "removes the class 'update-pending' from input elements when initial (DB) value is entered" do
        page.should_not have_css "input[name='quantity'].update-pending"
        fill_in "quantity", :with => 2
        page.should have_css "input[name='quantity'].update-pending"
        fill_in "quantity", :with => 5
        page.should_not have_css "input[name='quantity'].update-pending"
      end
    end

    context "submitting data to the server" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1, :quantity => 5 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays an update button which submits pending changes" do
        fill_in "quantity", :with => 2
        page.should have_selector "input[name='quantity'].update-pending"
        page.should_not have_selector "input[name='quantity'].update-success"
        page.should have_button "Update"
        click_button "Update"
        page.should_not have_selector "input[name='quantity'].update-pending"
        page.should have_selector "input[name='quantity'].update-success"
      end
    end
  end

  context "using page controls" do
    before :each do
      login_to_admin_section
    end

    let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
    let!(:li1) { FactoryGirl.create(:line_item, order: o1, :quantity => 5 ) }

    context "using column display toggle" do
      it "shows a column display toggle button, which shows a list of columns when clicked" do
        visit '/admin/orders/bulk_management'

        page.should have_selector "th", :text => "NAME"
        page.should have_selector "th", :text => "ORDER DATE"
        page.should have_selector "th", :text => "PRODUCER"
        page.should have_selector "th", :text => "PRODUCT: UNIT"
        page.should have_selector "th", :text => "QUANTITY"
        page.should have_selector "th", :text => "MAX"

        first("div#columns_dropdown", :text => "COLUMNS").click
        first("div#columns_dropdown div.menu div.menu_item", text: "Producer").click

        page.should_not have_selector "th", :text => "PRODUCER"
        page.should have_selector "th", :text => "NAME"
        page.should have_selector "th", :text => "ORDER DATE"
        page.should have_selector "th", :text => "PRODUCT: UNIT"
        page.should have_selector "th", :text => "QUANTITY"
        page.should have_selector "th", :text => "MAX"
      end
    end

    context "using drop down seletors" do
      let!(:oc1) { FactoryGirl.create(:order_cycle) }
      let!(:oc2) { FactoryGirl.create(:order_cycle) }
      let!(:s1) { oc1.suppliers.first }
      let!(:s2) { oc2.suppliers.last }
      let!(:d1) { oc1.distributors.first }
      let!(:d2) { oc2.distributors.last }
      let!(:p1) { FactoryGirl.create(:product, supplier: s1) }
      let!(:p2) { FactoryGirl.create(:product, supplier: s2) }
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now, distributor: d1, order_cycle: oc1 ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now, distributor: d2, order_cycle: oc2 ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1, product: p1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2, product: p2 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays a select box for producers, which filters line items by the selected supplier" do
        supplier_names = ["All"]
        Enterprise.is_primary_producer.each{ |e| supplier_names << e.name }
        find("div.select2-container#s2id_supplier_filter").click
        supplier_names.each { |sn| page.should have_selector "div.select2-drop-active ul.select2-results li", text: sn }
        find("div.select2-container#s2id_supplier_filter").click
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        select2_select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays all line items when 'All' is selected from supplier filter" do
        select2_select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select2_select "All", from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays a select box for distributors, which filters line items by the selected distributor" do
        distributor_names = ["All"]
        Enterprise.is_distributor.each{ |e| distributor_names << e.name }
        find("div.select2-container#s2id_distributor_filter").click
        distributor_names.each { |dn| page.should have_selector "div.select2-drop-active ul.select2-results li", text: dn }
        find("div.select2-container#s2id_distributor_filter").click
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        select2_select d1.name, from: "distributor_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays all line items when 'All' is selected from distributor filter" do
        select2_select d1.name, from: "distributor_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select2_select "All", from: "distributor_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays a select box for order cycles, which filters line items by the selected order cycle" do
        order_cycle_names = ["All"]
        OrderCycle.all.each{ |oc| order_cycle_names << oc.name }
        find("div.select2-container#s2id_order_cycle_filter").click
        order_cycle_names.each { |ocn| page.should have_selector "div.select2-drop-active ul.select2-results li", text: ocn }
        find("div.select2-container#s2id_order_cycle_filter").click
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        select2_select oc1.name, from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays all line items when 'All' is selected from order_cycle filter" do
        select2_select oc1.name, from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select2_select "All", from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "allows filters to be used in combination" do
        select2_select oc1.name, from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select2_select d1.name, from: "distributor_filter"
        select2_select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select2_select d2.name, from: "distributor_filter"
        select2_select s2.name, from: "supplier_filter"
        page.should_not have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select2_select oc2.name, from: "order_cycle_filter"
        page.should_not have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays a 'Clear All' button which sets all select filters to 'All'" do
        select2_select oc1.name, from: "order_cycle_filter"
        select2_select d1.name, from: "distributor_filter"
        select2_select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        page.should have_button "Clear All"
        click_button "Clear All"
        page.should have_selector "div#s2id_order_cycle_filter a.select2-choice", text: "All"
        page.should have_selector "div#s2id_supplier_filter a.select2-choice", text: "All"
        page.should have_selector "div#s2id_distributor_filter a.select2-choice", text: "All"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end
    end

    context "using quick search" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o3) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2 ) }
      let!(:li3) { FactoryGirl.create(:line_item, order: o3 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays a quick search input" do
        page.should have_field "quick_search"
      end

      it "filters line items based on their attributes and the contents of the quick search input" do
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        page.should have_selector "tr#li_#{li3.id}", visible: true
        fill_in "quick_search", :with => o1.email
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        page.should_not have_selector "tr#li_#{li3.id}", visible: true
      end
    end

    context "using date restriction controls" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: (Date.today - 8).strftime("%F %T") ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o3) { FactoryGirl.create(:order, state: 'complete', completed_at: (Date.today + 2).strftime("%F %T") ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1, :quantity => 1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2, :quantity => 2 ) }
      let!(:li3) { FactoryGirl.create(:line_item, order: o3, :quantity => 3 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays date fields for filtering orders, with default values set" do
        one_week_ago = Date.today.prev_day(7).strftime("%F")
        tonight = Date.tomorrow.strftime("%F")
        page.should have_field "start_date_filter", with: one_week_ago
        page.should have_field "end_date_filter", with: tonight
      end

      it "only loads line items whose orders meet the date restriction criteria" do
        page.should_not have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        page.should_not have_selector "tr#li_#{li3.id}", visible: true
      end

      it "displays only line items whose orders meet the date restriction criteria, when changed" do
        fill_in "start_date_filter", :with => (Date.today - 9).strftime("%F")
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        page.should_not have_selector "tr#li_#{li3.id}", visible: true

        fill_in "end_date_filter", :with => (Date.today + 3).strftime("%F")
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        page.should have_selector "tr#li_#{li3.id}", visible: true
      end

      context "when pending changes exist" do
        it "alerts the user when dates are altered" do
          li2_quantity_column = find("tr#li_#{li2.id} td.quantity")
          li2_quantity_column.fill_in "quantity", :with => li2.quantity + 1
          page.should_not have_button "IGNORE"
          page.should_not have_button "SAVE"
          fill_in "start_date_filter", :with => (Date.today - 9).strftime("%F %T")
          page.should have_button "IGNORE"
          page.should have_button "SAVE"
        end

        it "saves pendings changes when 'SAVE' button is clicked" do
          within("tr#li_#{li2.id} td.quantity") do
            page.fill_in "quantity", :with => (li2.quantity + 1).to_s
          end
          fill_in "start_date_filter", :with => (Date.today - 9).strftime("%F %T")
          click_button "SAVE"
          page.should_not have_selector "input[name='quantity'].update-pending"
          within("tr#li_#{li2.id} td.quantity") do
            page.should have_field "quantity", :with => ( li2.quantity + 1 ).to_s
          end
        end

        it "ignores pending changes when 'IGNORE' button is clicked" do
          within("tr#li_#{li2.id} td.quantity") do
            page.fill_in "quantity", :with => (li2.quantity + 1).to_s
          end
          fill_in "start_date_filter", :with => (Date.today - 9).strftime("%F %T")
          click_button "IGNORE"
          page.should_not have_selector "input[name='quantity'].update-pending"
          within("tr#li_#{li2.id} td.quantity") do
            page.should have_field "quantity", :with => ( li2.quantity ).to_s
          end
        end
      end
    end

    context "bulk action controls" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2 ) }

      before :each do
        visit '/admin/orders/bulk_management'
      end

      it "displays a checkbox for each line item in the list" do
        page.should have_selector "tr#li_#{li1.id} input[type='checkbox'][name='bulk']"
        page.should have_selector "tr#li_#{li2.id} input[type='checkbox'][name='bulk']"
      end

      it "displays a checkbox to which toggles the 'checked' state of all checkboxes" do
        check "toggle_bulk"
        page.all("input[type='checkbox'][name='bulk']").each{ |checkbox| checkbox.checked?.should == true }
        uncheck "toggle_bulk"
        page.all("input[type='checkbox'][name='bulk']").each{ |checkbox| checkbox.checked?.should == false }
      end

      it "displays a bulk action select box with a list of actions" do
        list_of_actions = ['Delete Selected']
        find("div#bulk_actions_dropdown").click
        within("div#bulk_actions_dropdown") do
          list_of_actions.each { |action_name| page.should have_selector "div.menu_item", text: action_name }
        end
      end

      context "performing actions" do
        it "deletes selected items" do
          page.should have_selector "tr#li_#{li1.id}", visible: true
          page.should have_selector "tr#li_#{li2.id}", visible: true
          within("tr#li_#{li2.id} td.bulk") do
            check "bulk"
          end
          find("div#bulk_actions_dropdown").click
          find("div#bulk_actions_dropdown div.menu_item", :text => "Delete Selected" ).click
          page.should have_selector "tr#li_#{li1.id}", visible: true
          page.should_not have_selector "tr#li_#{li2.id}", visible: true
        end
      end

      context "when a filter has been applied" do
        it "only toggles checkboxes which are in filteredLineItems" do
          fill_in "quick_search", with: o1.number
          check "toggle_bulk"
          fill_in "quick_search", with: ''
          find("tr#li_#{li1.id} input[type='checkbox'][name='bulk']").checked?.should == true
          find("tr#li_#{li2.id} input[type='checkbox'][name='bulk']").checked?.should == false
          find("input[type='checkbox'][name='toggle_bulk']").checked?.should == false
        end

        it "only applies the delete action to filteredLineItems" do
          check "toggle_bulk"
          fill_in "quick_search", with: o1.number
          find("div#bulk_actions_dropdown").click
          find("div#bulk_actions_dropdown div.menu_item", :text => "Delete Selected" ).click
          fill_in "quick_search", with: ''
          page.should_not have_selector "tr#li_#{li1.id}", visible: true
          page.should have_selector "tr#li_#{li2.id}", visible: true
        end
      end
    end

    context "using action buttons" do
      context "using delete buttons" do
        let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
        let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
        let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
        let!(:li2) { FactoryGirl.create(:line_item, order: o2 ) }

        before :each do
          visit '/admin/orders/bulk_management'
        end

        it "shows a delete button for each line item" do
          page.should have_selector "a.delete-line-item", :count => 2
        end

        it "removes a line item when the relevant delete button is clicked" do
          first("a.delete-line-item").click
          page.should_not have_selector "a.delete-line-item", :count => 2
          page.should have_selector "a.delete-line-item", :count => 1
          visit '/admin/orders/bulk_management'
          page.should have_selector "a.delete-line-item", :count => 1
        end
      end
    end

    context "clicking the link on variant name" do
      let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:li1) { FactoryGirl.create(:line_item, order: o1 ) }
      let!(:li2) { FactoryGirl.create(:line_item, order: o2 ) }
      let!(:p3) { FactoryGirl.create(:product_with_option_types, group_buy: true, group_buy_unit_size: 5000, variant_unit: "weight", variants: [FactoryGirl.create(:variant, unit_value: 1000)] ) }
      let!(:v3) { p3.variants.first }
      let!(:o3) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now ) }
      let!(:li3) { FactoryGirl.create(:line_item, order: o3, variant: v3, quantity: 3, max_quantity: 6 ) }
      let!(:li4) { FactoryGirl.create(:line_item, order: o2, variant: v3, quantity: 1, max_quantity: 3 ) }

      before :each do
        visit '/admin/orders/bulk_management'
        within "tr#li_#{li3.id}" do
          find("a", text: li3.product.name + ": " + li3.variant.options_text).click
        end
      end

      it "displays group buy calc box" do
        page.should have_selector "div#group_buy_calculation", :visible => true

        within "div#group_buy_calculation" do
          page.should have_text "Group Buy Unit Size"
          page.should have_text "5 kg"
          page.should have_text "Total Quantity Ordered"
          page.should have_text "4 kg"
          page.should have_text "Max Quantity Ordered"
          page.should have_text "9 kg"
          page.should have_text "Current Fulfilled Units"
          page.should have_text "0.8"
          page.should have_text "Max Fulfilled Units"
          page.should have_text "1.8"
          page.should have_selector "div.shared_resource", :visible => true
          within "div.shared_resource" do
            page.should have_selector "span", :text => "Shared Resource?"
            page.should have_selector "input#shared_resource"
          end
        end
      end

      it "all line items of the same variant" do
        page.should_not have_selector "tr#li_#{li1.id}", :visible => true
        page.should_not have_selector "tr#li_#{li2.id}", :visible => true
        page.should have_selector "tr#li_#{li3.id}", :visible => true
        page.should have_selector "tr#li_#{li4.id}", :visible => true
      end

      context "clicking 'Clear' in group buy box" do
        before :each do
          find("a", text: "Clear").click
        end

        it "shows all products and clears group buy box" do
          page.should_not have_selector "div#group_buy_calculation", :visible => true
          page.should have_selector "tr#li_#{li1.id}", :visible => true
          page.should have_selector "tr#li_#{li2.id}", :visible => true
          page.should have_selector "tr#li_#{li3.id}", :visible => true
          page.should have_selector "tr#li_#{li4.id}", :visible => true
        end
      end
    end
  end

  context "as an enterprise manager" do
    let(:s1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:s2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:d1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:d2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let!(:o1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now, distributor: d1 ) }
    let!(:o2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.now, distributor: d2 ) }
    let!(:line_item_distributed) { FactoryGirl.create(:line_item, order: o1 ) }
    let!(:line_item_not_distributed) { FactoryGirl.create(:line_item, order: o2 ) }

    before(:each) do
      @enterprise_user = create_enterprise_user
      @enterprise_user.enterprise_roles.build(enterprise: s1).save
      @enterprise_user.enterprise_roles.build(enterprise: d1).save

      login_to_admin_as @enterprise_user
    end

    it "shows only line item from orders that I supply" do
      visit '/admin/orders/bulk_management'

      page.should have_selector "tr#li_#{line_item_distributed.id}", :visible => true
      page.should_not have_selector "tr#li_#{line_item_not_distributed.id}", :visible => true
    end
  end
end
