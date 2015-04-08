require 'open_food_network/permissions'
require 'open_food_network/order_cycle_form_applicator'

module Admin
  class OrderCyclesController < ResourceController
    include OrderCyclesHelper

    before_filter :load_data_for_index, :only => :index
    before_filter :require_coordinator, only: :new
    before_filter :remove_protected_attrs, only: [:update]
    around_filter :protect_invalid_destroy, only: :destroy


    def show
      respond_to do |format|
        format.html
        format.json do
          render json: Api::Admin::OrderCycleSerializer.new(@order_cycle, current_user: spree_current_user).to_json
        end
      end
    end

    def new
      respond_to do |format|
        format.html
        format.json do
          render json: Api::Admin::OrderCycleSerializer.new(@order_cycle, current_user: spree_current_user).to_json
        end
      end
    end

    def create
      @order_cycle = OrderCycle.new(params[:order_cycle])

      respond_to do |format|
        if @order_cycle.save
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle, spree_current_user).go!

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
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle, spree_current_user).go!

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
    def collection(show_more=false)
      ocs = OrderCycle.accessible_by(spree_current_user)

      ocs.undated +
        ocs.soonest_closing +
        ocs.soonest_opening +
        (show_more ? ocs.closed : ocs.recently_closed)
    end

    private
    def load_data_for_index
      @show_more = !!params[:show_more]
      @order_cycle_set = OrderCycleSet.new :collection => collection(@show_more)
    end

    def require_coordinator
      if params[:coordinator_id] && @order_cycle.coordinator = permitted_coordinating_enterprises_for(@order_cycle).find_by_id(params[:coordinator_id])
        return
      end

      available_coordinators = permitted_coordinating_enterprises_for(@order_cycle).select(&:confirmed?)
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

    def protect_invalid_destroy
      begin
        yield
      rescue ActiveRecord::InvalidForeignKey
        redirect_to main_app.admin_order_cycles_url
        flash[:error] = "That order cycle has been selected by a customer and cannot be deleted. To prevent customers from accessing it, please close it instead."
      end
    end

    def remove_protected_attrs
      params[:order_cycle].delete :coordinator_id

      unless spree_current_user.admin? || Enterprise.managed_by(spree_current_user).include?(@order_cycle.coordinator)
        params[:order_cycle].delete_if{ |k,v| [:name, :orders_open_at, :orders_close_at].include? k.to_sym }
      end
    end
  end
end
