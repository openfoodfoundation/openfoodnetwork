require 'spec_helper'

feature %q{
    As a consumer
    I want to see a list of producers
    So that I can shop at hubs distributing their products 
} do
  include UIComponentHelper
  let!(:producer) { create(:supplier_enterprise) }

  it "shows all producers" do
    visit producers_path
    page.should have_content producer.name
  end
end
