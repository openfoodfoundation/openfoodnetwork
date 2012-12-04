require 'open_food_web/order_cycle_form_applicator'

module OpenFoodWeb
  describe OrderCycleFormApplicator do
    it "creates new exchanges for incoming_exchanges" do
      coordinator_id = 123
      supplier_id = 456

      oc = double(:order_cycle, :coordinator_id => coordinator_id, :exchanges => [], :incoming_exchanges => [{:enterprise_id => supplier_id}])

      applicator = OrderCycleFormApplicator.new(oc)

      applicator.should_receive(:exchange_exists?).and_return(false)
      applicator.should_receive(:add_exchange).with(supplier_id, coordinator_id)
      applicator.should_receive(:destroy_untouched_exchanges)

      applicator.go!
    end

    it "updates existing exchanges for incoming_exchanges" do
      coordinator_id = 123
      supplier_id = 456

      oc = double(:order_cycle,
                  :coordinator_id => coordinator_id,
                  :exchanges => [double(:exchange, :sender_id => supplier_id, :receiver_id => coordinator_id)],
                  :incoming_exchanges => [{:enterprise_id => supplier_id}])

      applicator = OrderCycleFormApplicator.new(oc)

      applicator.should_receive(:exchange_exists?).and_return(true)
      applicator.should_receive(:update_exchange).with(supplier_id, coordinator_id)
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
      applicator.untouched_exchanges.should == [exchange]
    end
  end
end
