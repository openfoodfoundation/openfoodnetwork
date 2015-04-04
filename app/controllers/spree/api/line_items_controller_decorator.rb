Spree::Api::LineItemsController.class_eval do
  after_filter :apply_enterprise_fees, :only => :update

  def apply_enterprise_fees
    authorize! :read, order
    order.update_distribution_charge!
  end
end


#when we update a line item the .update_distribution_charge! is called
# order.should_receive .update_distribution_charge!
# check fails when absent

# in order model check that .update_distribution_charge! is properly tested.
# think through use cases - existing completed order
# currently likely just used to complete orders so add test case that works on a completed order
