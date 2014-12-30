require 'spec_helper'

describe ProducerMailer do
  let(:supplier) { create(:supplier_enterprise) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:supplier)   { create(:supplier_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

  before do
    # ActionMailer::Base.delivery_method = :test
    # ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
    order.set_order_cycle! order_cycle
  end

  after do
    ActionMailer::Base.deliveries.clear
  end

  it "should send an email when an order cycle is closed" do
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    ActionMailer::Base.deliveries.count.should == 3
  end

  it "sets a reply-to of the enterprise email" do
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    ActionMailer::Base.deliveries.last.reply_to.should == [supplier.email]
  end

  it "cc's the enterprise" do
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    ActionMailer::Base.deliveries.last.cc.should == [supplier.email]
  end

  it "contains an aggregated list of produce" do
    puts order.to_yaml
    order.state= 'complete'
    puts order.to_yaml
    puts Spree::Order.complete.not_state(:canceled).size
    # puts order_cycle.orders
    # puts order.class
    # puts order.class.instance_methods.sort
    # puts order.managed_by supplier
    ProducerMailer.order_cycle_report(supplier, order_cycle).deliver
    puts ActionMailer::Base.deliveries.last.body
  end
end
