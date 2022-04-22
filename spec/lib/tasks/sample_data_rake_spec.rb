# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe 'sample_data.rake' do
  before(:all) do
    Rake.application.rake_require 'tasks/sample_data'
    Rake::Task.define_task(:environment)
  end

  before do
    # Create seed data required by the sample data.
    create(:user)
    DefaultStockLocation.find_or_create
    DefaultShippingCategory.find_or_create
  end

  it "creates some sample data to play with" do
    Rake.application.invoke_task "ofn:sample_data"

    expect(EnterpriseGroup.count).to eq 1
    expect(Customer.count).to eq 2
    expect(Spree::Order.count).to eq 5
  end
end
