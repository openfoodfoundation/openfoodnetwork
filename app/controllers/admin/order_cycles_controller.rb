require 'open_food_web/order_cycle_form_applicator'

module Admin
  class OrderCyclesController < ResourceController
    before_filter :load_order_cycle_set, :only => :index

    def new
      respond_to do |format|
        format.html
        format.json
      end
    end

    def create
      @order_cycle = OrderCycle.new(params[:order_cycle])

      respond_to do |format|
        if @order_cycle.save
          OpenFoodWeb::OrderCycleFormApplicator.new(@order_cycle).go!

          flash[:notice] = 'Your order cycle has been created.'
          format.html { redirect_to admin_order_cycles_path }
          format.json { render :json => {:success => true} }
        else
          format.html
          format.json { render :json => {:success => false} }
        end
      end
    end



    private
    def load_order_cycle_set
      @order_cycle_set = OrderCycleSet.new :collection => collection
    end
  end
end
