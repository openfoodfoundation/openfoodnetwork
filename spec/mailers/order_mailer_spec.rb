require 'spec_helper'

describe Spree::OrderMailer do
  after do
    ActionMailer::Base.deliveries.clear
  end

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @bill_address = create(:address)
    @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
    @distributor = create(:distributor_enterprise, :address => @distributor_address)
    product = create(:product)
    product_distribution = create(:product_distribution, :product => product, :distributor => @distributor)
    @shipping_instructions = "pick up on thursday please!"
    @order1 = create(:order, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)
    ActionMailer::Base.deliveries = []
  end

  it "should send an email when given an order" do
    Spree::OrderMailer.confirm_email(@order1.id).deliver
    ActionMailer::Base.deliveries.count.should == 3
  end

  it "sets a reply-to of the enterprise email" do
    Spree::OrderMailer.confirm_email(@order1.id).deliver
    ActionMailer::Base.deliveries.first.reply_to.should == [@distributor.email]
  end

  it "ccs the enterprise" do
    Spree::OrderMailer.confirm_email(@order1.id).deliver
    ActionMailer::Base.deliveries.first.cc.should == [@distributor.email]
  end
end
