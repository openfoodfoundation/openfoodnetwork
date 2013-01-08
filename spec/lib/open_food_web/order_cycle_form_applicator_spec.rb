require 'open_food_web/order_cycle_form_applicator'

module OpenFoodWeb
  describe OrderCycleFormApplicator do
    context "integration specs" do
      before(:all) do
        require 'spec_helper'
      end

      it "checks whether exchanges exist" do
        oc = FactoryGirl.create(:simple_order_cycle)
        exchange = FactoryGirl.create(:exchange, order_cycle: oc)
        applicator = OrderCycleFormApplicator.new(oc)

        applicator.send(:exchange_exists?, exchange.sender_id, exchange.receiver_id).should be_true
        applicator.send(:exchange_exists?, exchange.receiver_id, exchange.sender_id).should be_false
        applicator.send(:exchange_exists?, exchange.sender_id, 999).should be_false
        applicator.send(:exchange_exists?, 999, exchange.receiver_id).should be_false
        applicator.send(:exchange_exists?, 999, 888).should be_false
      end

      it "adds exchanges" do
        oc = FactoryGirl.create(:simple_order_cycle)
        applicator = OrderCycleFormApplicator.new(oc)
        sender = FactoryGirl.create(:enterprise)
        receiver = FactoryGirl.create(:enterprise)
        variant1 = FactoryGirl.create(:variant)
        variant2 = FactoryGirl.create(:variant)

        applicator.send(:touched_exchanges=, [])
        applicator.send(:add_exchange, sender.id, receiver.id, [variant1.id, variant2.id])

        exchange = Exchange.last
        exchange.sender.should == sender
        exchange.receiver.should == receiver
        exchange.variants.sort.should == [variant1, variant2].sort

        applicator.send(:touched_exchanges).should == [exchange]
      end

      it "updates exchanges"
    end

    context "unit specs" do
      it "creates new exchanges for incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456

        incoming_exchange = {:enterprise_id => supplier_id, :exchange_variants => {'1' => true, '2' => false, '3' => true}}

        oc = double(:order_cycle, :coordinator_id => coordinator_id, :exchanges => [], :incoming_exchanges => [incoming_exchange])

        applicator = OrderCycleFormApplicator.new(oc)

        applicator.should_receive(:exchange_variant_ids).with(incoming_exchange).and_return([1, 3])
        applicator.should_receive(:exchange_exists?).and_return(false)
        applicator.should_receive(:add_exchange).with(supplier_id, coordinator_id, [1, 3])
        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "updates existing exchanges for incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456

        incoming_exchange = {:enterprise_id => supplier_id, :exchange_variants => {'1' => true, '2' => false, '3' => true}}

        oc = double(:order_cycle,
                    :coordinator_id => coordinator_id,
                    :exchanges => [double(:exchange, :sender_id => supplier_id, :receiver_id => coordinator_id)],
                    :incoming_exchanges => [incoming_exchange])

        applicator = OrderCycleFormApplicator.new(oc)

        applicator.should_receive(:exchange_variant_ids).with(incoming_exchange).and_return([1, 3])
        applicator.should_receive(:exchange_exists?).and_return(true)
        applicator.should_receive(:update_exchange).with(supplier_id, coordinator_id, [1, 3])
        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "removes exchanges that are no longer present in incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456
        exchange = double(:exchange, :sender_id => supplier_id, :receiver_id => coordinator_id)

        oc = double(:order_cycle,
                    :coordinator_id => coordinator_id,
                    :exchanges => [exchange],
                    :incoming_exchanges => [])

        applicator = OrderCycleFormApplicator.new(oc)

        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
        applicator.send(:untouched_exchanges).should == [exchange]
      end

      it "converts exchange variant ids hash to an array of ids" do
        applicator = OrderCycleFormApplicator.new(nil)

        applicator.send(:exchange_variant_ids, {:enterprise_id => 123, :exchange_variants => {'1' => true, '2' => false, '3' => true}}).should == [1, 3]
      end
    end
  end
end
