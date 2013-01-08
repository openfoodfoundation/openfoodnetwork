require 'open_food_web/order_cycle_form_applicator'

module OpenFoodWeb
  describe OrderCycleFormApplicator do
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
      applicator.untouched_exchanges.should == [exchange]
    end

    it "converts exchange variant ids hash to an array of ids" do
      applicator = OrderCycleFormApplicator.new(nil)

      applicator.send(:exchange_variant_ids, {:enterprise_id => 123, :exchange_variants => {'1' => true, '2' => false, '3' => true}}).should == [1, 3]
    end
  end
end
