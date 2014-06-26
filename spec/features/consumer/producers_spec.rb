require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of producers
    So that I can shop at hubs distributing their products 
}, js: true do
  include UIComponentHelper
  let!(:producer) { create(:supplier_enterprise) }
  let!(:invisible_producer) { create(:supplier_enterprise, visible: false) }
  
  before do
    visit producers_path
  end

  it "shows all producers with expandable details" do
    page.should have_content producer.name
    expand_active_table_node producer.name
    page.should have_content producer.supplied_taxons.join(', ')
  end
  
  it "doesn't show invisible producers" do
    page.should_not have_content invisible_producer.name
  end
end
