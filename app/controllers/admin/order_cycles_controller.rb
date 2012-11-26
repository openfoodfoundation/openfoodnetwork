module Admin
  class OrderCyclesController < ResourceController
    before_filter :load_order_cycle_set, :only => :index

    def new
      respond_to do |format|
        format.html
        format.json
      end
    end


    private
    def load_order_cycle_set
      @order_cycle_set = OrderCycleSet.new :collection => collection
    end
  end
end
