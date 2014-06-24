require 'spec_helper'

feature 'Home', js: true do
  include AuthenticationWorkflow
  include UIComponentHelper

  let!(:distributor) { create(:distributor_enterprise) }
  let(:d1) { create(:distributor_enterprise) }
  let(:d2) { create(:distributor_enterprise) }
  let!(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }
  let!(:producer) { create(:supplier_enterprise) }
  let!(:er) { create(:enterprise_relationship, parent: distributor, child: producer) }

  before do
    visit "/" 
  end

  it "shows all hubs" do
    page.should have_content distributor.name
    expand_active_table_node distributor.name
    page.should have_content "Shop at #{distributor.name}" 
  end

  it "should grey out hubs that are not in an order cycle" do
    create(:simple_product, distributors: [d1, d2])
    visit root_path
    page.should have_selector 'hub.inactive'
    page.should have_selector 'hub.inactive',   text: d2.name
  end

  it "should link to the hub page" do
    follow_active_table_node distributor.name
    current_path.should == "/shop"
  end

  it "should show hub producer modals" do
    expand_active_table_node distributor.name
    page.should have_content producer.name
    open_enterprise_modal producer
    modal_should_be_open_for producer
  end
end
