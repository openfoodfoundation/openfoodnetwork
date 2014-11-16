require 'spec_helper'

describe ProducerMailer do
  let(:p)   { create(:simple_product, supplier: s) }
  let(:supplier)   { create(:supplier_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }

  after do
    ActionMailer::Base.deliveries.clear
  end

  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  it "should send an email when an order cycle is closed" do
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    ActionMailer::Base.deliveries.count.should == 3
  end

  it "sets a reply-to of the enterprise email" do
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    ActionMailer::Base.deliveries.last.reply_to.should == [supplier.email]
  end

  it "ccs the enterprise" do
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    ActionMailer::Base.deliveries.last.cc.should == [supplier.email]
  end
end
