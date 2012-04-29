require 'spec_helper'

describe Spree::Supplier do

  describe "associations" do
    it { should have_many(:products) }
    it { should belong_to(:address) }
  end

  it "should have an address"

  it "should add an address on save"

  describe 'validations' do
    # it{ should validate_presence_of(:comment) }
  end

end
