require 'open_food_network/permissions'
require 'open_food_network/order_cycle_form_applicator'

module Admin
  class OrderCyclesController < ResourceController
    include OrderCyclesHelper

    before_filter :load_order_cycle_set, :only => :index
    before_filter :require_coordinator, only: :new

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
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle, order_cycle_permitted_enterprises).go!

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
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle, order_cycle_permitted_enterprises).go!

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

      ocs.undated +
        ocs.soonest_closing +
        ocs.soonest_opening +
        ocs.recently_closed
    end

    private
    def load_order_cycle_set
      @order_cycle_enterprises = OpenFoodNetwork::Permissions.new(spree_current_user).order_cycle_enterprises
      @order_cycle_set = OrderCycleSet.new :collection => collection
    end

    def require_coordinator
      if params[:coordinator_id] && @order_cycle.coordinator = order_cycle_coordinating_enterprises.find_by_id(params[:coordinator_id])
        return
      end

      available_coordinators = order_cycle_coordinating_enterprises.select(&:confirmed?)
      case available_coordinators.count
      when 0
        flash[:error] = "None of your enterprises have permission to coordinate an order cycle"
        redirect_to main_app.admin_order_cycles_path
      when 1
        @order_cycle.coordinator = available_coordinators.first
      else
        flash[:error] = "You don't have permission to create an order cycle coordinated by that enterprise" if params[:coordinator_id]
        render :set_coordinator
      end
    end
  end
end
