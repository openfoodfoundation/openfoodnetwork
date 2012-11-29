require 'open_food_web/order_cycle_form_applicator'

module OpenFoodWeb
  describe OrderCycleFormApplicator do
    it "creates new exchanges for incoming_exchanges" do
      coordinator_id = 123
      supplier_id = 456

      oc = double(:order_cycle, :coordinator_id => coordinator_id, :incoming_exchanges => [{:enterprise_id => supplier_id}])

      applicator = OrderCycleFormApplicator.new(oc)

      applicator.should_receive(:add_exchange).with(supplier_id, coordinator_id)

      applicator.go!
    end

    it "updates existing exchanges for incoming_exchanges"
  end
end
