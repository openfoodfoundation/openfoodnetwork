require 'open_food_network/order_cycle_form_applicator'

module Admin
  class OrderCyclesController < ResourceController
    before_filter :load_order_cycle_set, :only => :index

    def show
      respond_to do |format|
        format.html
        format.json
      end
    end

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
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle).go!

          flash[:notice] = 'Your order cycle has been created.'
          format.html { redirect_to admin_order_cycles_path }
          format.json { render :json => {:success => true} }
        else
          format.html
          format.json { render :json => {:success => false} }
        end
      end
    end

    def update
      @order_cycle = OrderCycle.find params[:id]

      respond_to do |format|
        if @order_cycle.update_attributes(params[:order_cycle])
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle).go!

          flash[:notice] = 'Your order cycle has been updated.'
          format.html { redirect_to admin_order_cycles_path }
          format.json { render :json => {:success => true} }
        else
          format.html
          format.json { render :json => {:success => false} }
        end
      end
    end

    def bulk_update
      @order_cycle_set = OrderCycleSet.new(params[:order_cycle_set])
      if @order_cycle_set.save
        redirect_to main_app.admin_order_cycles_path, :notice => 'Order cycles have been updated.'
      else
        render :index
      end
    end

    def clone
      @order_cycle = OrderCycle.find params[:id]
      @order_cycle.clone!
      redirect_to main_app.admin_order_cycles_path, :notice => "Your order cycle #{@order_cycle.name} has been cloned."
    end


    protected
    def collection
      ocs = OrderCycle.managed_by(spree_current_user)

      ocs.soonest_closing +
        ocs.soonest_opening +
        ocs.most_recently_closed
    end

    private
    def load_order_cycle_set
      @order_cycle_set = OrderCycleSet.new :collection => collection
    end
  end
end
