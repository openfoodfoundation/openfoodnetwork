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

      it "displays a 'loading' splash for line items" do
        page.should have_selector "div.loading", :text => "Loading Line Items..."
      end

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

    context "using tabs to hide and display page controls" do
      it "shows a column display toggle button, which shows a list of columns when clicked" do
        visit '/admin/orders/bulk_management'

        page.should have_selector "div.column_toggle", :visible => false

        page.should have_selector "div.option_tab_titles h6.unselected", :text => "Toggle Columns"
        first("div.option_tab_titles h6", :text => "Toggle Columns").click

        page.should have_selector "div.option_tab_titles h6.selected", :text => "Toggle Columns"
        page.should have_selector "div.column_toggle", :visible => true
        page.should have_selector "li.column-list-item", text: "Producer"

        page.should have_selector "div.filters", :visible => false

        page.should have_selector "div.option_tab_titles h6.unselected", :text => "Filter Line Items"
        first("div.option_tab_titles h6", :text => "Filter Line Items").click

        page.should have_selector "div.option_tab_titles h6.unselected", :text => "Toggle Columns"
        page.should have_selector "div.option_tab_titles h6.selected", :text => "Filter Line Items"
        page.should have_selector "div.filters", :visible => true
        page.should have_selector "li.column-list-item", text: "Producer"

        first("div.option_tab_titles h6", :text => "Filter Line Items").click

        page.should have_selector "div.option_tab_titles h6.unselected", :text => "Filter Line Items"
        page.should have_selector "div.option_tab_titles h6.unselected", :text => "Toggle Columns"
        page.should have_selector "div.filters", :visible => false
        page.should have_selector "div.column_toggle", :visible => false
      end
    end

    context "using column display toggle" do
      it "shows a column display toggle button, which shows a list of columns when clicked" do
        visit '/admin/orders/bulk_management'

        first("div.option_tab_titles h6", :text => "Toggle Columns").click

        page.should have_selector "th", :text => "NAME"
        page.should have_selector "th", :text => "ORDER DATE"
        page.should have_selector "th", :text => "PRODUCER"
        page.should have_selector "th", :text => "PRODUCT: UNIT"
        page.should have_selector "th", :text => "QUANTITY"
        page.should have_selector "th", :text => "MAX"

        page.should have_selector "div.option_tab_titles h6", :text => "Toggle Columns"

        page.should have_selector "div ul.column-list li.column-list-item", text: "Producer"
        first("li.column-list-item", text: "Producer").click

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
        page.should have_select "supplier_filter", with_options: [s1.name,s2.name]
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays all line items when 'All' is selected from supplier filter" do
        select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select "All", from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays a select box for distributors, which filters line items by the selected distributor" do
        page.should have_select "distributor_filter", with_options: [d1.name,d2.name]
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        select d1.name, from: "distributor_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays all line items when 'All' is selected from distributor filter" do
        select d1.name, from: "distributor_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select "All", from: "distributor_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays a select box for order cycles, which filters line items by the selected order cycle" do
        page.should have_select "order_cycle_filter", with_options: [oc1.name,oc2.name]
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        select oc1.name, from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
      end

      it "displays all line items when 'All' is selected from order_cycle filter" do
        select oc1.name, from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select "All", from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
      end

      it "allows filters to be used in combination" do
        select oc1.name, from: "order_cycle_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select d1.name, from: "distributor_filter"
        select s1.name, from: "supplier_filter"
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select d2.name, from: "distributor_filter"
        select s2.name, from: "supplier_filter"
        page.should_not have_selector "tr#li_#{li1.id}", visible: true
        page.should_not have_selector "tr#li_#{li2.id}", visible: true
        select oc2.name, from: "order_cycle_filter"
        page.should_not have_selector "tr#li_#{li1.id}", visible: true
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
        one_week_ago = (Date.today - 7).strftime("%F %T")
        tonight = Date.tomorrow.strftime("%F %T")
        page.should have_field "start_date_filter", with: one_week_ago
        page.should have_field "end_date_filter", with: tonight
      end

      it "only loads line items whose orders meet the date restriction criteria" do
        page.should_not have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        page.should_not have_selector "tr#li_#{li3.id}", visible: true
      end

      it "displays only line items whose orders meet the date restriction criteria, when changed" do
        first("div.option_tab_titles h6", :text => "Filter Line Items").click
        fill_in "start_date_filter", :with => (Date.today - 9).strftime("%F %T")
        page.should have_selector "tr#li_#{li1.id}", visible: true
        page.should have_selector "tr#li_#{li2.id}", visible: true
        page.should_not have_selector "tr#li_#{li3.id}", visible: true

        fill_in "end_date_filter", :with => (Date.today + 3).strftime("%F %T")
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
          first("div.option_tab_titles h6", :text => "Filter Line Items").click
          fill_in "start_date_filter", :with => (Date.today - 9).strftime("%F %T")
          page.should have_button "IGNORE"
          page.should have_button "SAVE"
        end

        it "saves pendings changes when 'SAVE' button is clicked" do
          within("tr#li_#{li2.id} td.quantity") do
            page.fill_in "quantity", :with => (li2.quantity + 1).to_s
          end
          first("div.option_tab_titles h6", :text => "Filter Line Items").click
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
          first("div.option_tab_titles h6", :text => "Filter Line Items").click
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
        page.should have_select "bulk_actions", :options => ["Delete"]
      end

      it "displays a bulk action button" do
        page.should have_button "bulk_execute"
      end

      context "performing actions" do
        it "deletes selected items" do
          page.should have_selector "tr#li_#{li1.id}", visible: true
          page.should have_selector "tr#li_#{li2.id}", visible: true
          within("tr#li_#{li2.id} td.bulk") do
            check "bulk"
          end
          select "Delete", :from => "bulk_actions"
          click_button "bulk_execute"
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
          select "Delete", :from => "bulk_actions"
          click_button "bulk_execute"
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
      let!(:li3) { FactoryGirl.create(:line_item, order: o3, variant: v3, quantity: 3 ) }
      let!(:li4) { FactoryGirl.create(:line_item, order: o2, variant: v3, quantity: 1 ) }

      before :each do
        visit '/admin/orders/bulk_management'
        within "tr#li_#{li3.id}" do
          click_link li3.variant.options_text
        end
      end

      it "displays group buy calc box" do
        page.should have_selector "div#group_buy_calculation", :visible => true

        within "div#group_buy_calculation" do
          page.should have_text "Group Buy Unit"
          page.should have_text "5 kg"
          page.should have_text "Fulfilled Units"
          page.should have_text "0.8"
          page.should have_text "Total Units Ordered"
          page.should have_text "4 kg"
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
          click_link 'Clear'
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
end
