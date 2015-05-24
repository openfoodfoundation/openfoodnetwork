require 'spec_helper'
require 'yaml'

describe ProducerMailer do
  let(:s1) { create(:supplier_enterprise, address: create(:address)) }
  let(:s2) { create(:supplier_enterprise, address: create(:address)) }
  let(:d1) { create(:distributor_enterprise, address: create(:address)) }
  let(:d2) { create(:distributor_enterprise, address: create(:address)) }
  let(:p1) { create(:product, price: 12.34, supplier: s1) }
  let(:p2) { create(:product, price: 23.45, supplier: s2) }
  let(:p3) { create(:product, price: 34.56, supplier: s1) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let!(:incoming_exchange) { order_cycle.exchanges.create! sender: s1, receiver: d1, incoming: true, receival_time: '10am Saturday', receival_instructions: 'Outside shed.' }

  let!(:order) do
    order = create(:order, distributor: d1, order_cycle: order_cycle, state: 'complete')
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end
  let!(:order_incomplete) do
    order = create(:order, distributor: d1, order_cycle: order_cycle, state: 'payment')
    order.line_items << create(:line_item, variant: p3.master)
    order.save
    order
  end
  let(:mail) { ActionMailer::Base.deliveries.last }

  before do
    ActionMailer::Base.deliveries.clear
    ProducerMailer.order_cycle_report(s1, order_cycle).deliver
  end

  it "should send an email when an order cycle is closed" do
    ActionMailer::Base.deliveries.count.should == 1
  end

  it "sets a reply-to of the enterprise email" do
    mail.reply_to.should == [s1.email]
  end

  it "includes receival time" do
    mail.body.should include '10am Saturday'
  end

  it "includes receival instructions" do
    mail.body.should include 'Outside shed.'
  end

  it "cc's the enterprise" do
    mail.cc.should == [s1.email]
  end

  it "contains an aggregated list of produce" do
    mail.body.to_s.each_line do |line|
      if line.include? p1.name
        line.should include 'QTY: 2'
      end
    end
  end

  it "does not include incomplete orders" do
    mail.body.should_not include p3.name
  end
end
