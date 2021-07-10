# frozen_string_literal: true

module Admin
  class OrderCyclesController < Admin::ResourceController
    include OrderCyclesHelper
    include PaperTrailLogging

    prepend_before_action :set_order_cycle_id, only: [:incoming, :outgoing]
    before_action :load_data_for_index, only: :index
    before_action :require_coordinator, only: :new
    before_action :remove_protected_attrs, only: [:update]
    before_action :require_order_cycle_set_params, only: [:bulk_update]
    around_action :protect_invalid_destroy, only: :destroy

    def index
      respond_to do |format|
        format.html
        format.json do
          render_as_json @collection,
                         ams_prefix: params[:ams_prefix],
                         current_user: spree_current_user,
                         subscriptions_count: OrderManagement::Subscriptions::Count.new(@collection)
        end
      end
    end

    def show
      respond_to do |format|
        format.json do
          render_as_json @order_cycle, current_user: spree_current_user
        end
      end
    end

    def new
      respond_to do |format|
        format.html
        format.json do
          render_as_json @order_cycle, current_user: spree_current_user
        end
      end
    end

    def create
      @order_cycle_form = OrderCycleForm.new(@order_cycle, order_cycle_params, spree_current_user)

      if @order_cycle_form.save
        flash[:notice] = I18n.t(:order_cycles_create_notice)
        render json: { success: true,
                       edit_path: main_app.admin_order_cycle_incoming_path(@order_cycle) }
      else
        render json: { errors: @order_cycle.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def set_order_cycle_id
      params[:id] = params[:order_cycle_id]
    end

    def update
      @order_cycle_form = OrderCycleForm.new(@order_cycle, order_cycle_params, spree_current_user)

      if @order_cycle_form.save
        respond_to do |format|
          flash[:notice] = I18n.t(:order_cycles_update_notice) if params[:reloading] == '1'
          format.html { redirect_back(fallback_location: root_path) }
          format.json { render json: { success: true } }
        end
      else
        render json: { errors: @order_cycle.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def bulk_update
      if order_cycle_set.andand.save
        render_as_json @order_cycles,
                       ams_prefix: 'index',
                       current_user: spree_current_user,
                       subscriptions_count: OrderManagement::Subscriptions::Count.new(@collection)
      else
        order_cycle = order_cycle_set.collection.find{ |oc| oc.errors.present? }
        render json: { errors: order_cycle.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def clone
      @order_cycle = OrderCycle.find params[:id]
      @order_cycle.clone!
      redirect_to main_app.admin_order_cycles_path,
                  notice: I18n.t(:order_cycles_clone_notice, name: @order_cycle.name)
    end

    # Send notifications to all producers who are part of the order cycle
    def notify_producers
      OrderCycleNotificationJob.perform_later params[:id].to_i

      redirect_to main_app.admin_order_cycles_path,
                  notice: I18n.t(:order_cycles_email_to_producers_notice)
    end

    protected

    def collection
      return Enterprise.where("1=0") unless json_request?
      return order_cycles_from_set if params[:order_cycle_set].present?

      ocs = order_cycles
      ocs.undated | ocs.soonest_closing | ocs.soonest_opening | ocs.closed
    end

    def collection_actions
      [:index, :bulk_update]
    end

    private

    def order_cycles
      if params[:as] == "distributor"
        order_cycles_as_distributor
      elsif params[:as] == "producer"
        order_cycles_as_producer
      else
        order_cycles_as_both
      end
    end

    def order_cycles_as_distributor
      OrderCycle.
        preload(:schedules).
        ransack(raw_params[:q]).
        result.
        involving_managed_distributors_of(spree_current_user).
        order('updated_at DESC')
    end

    def order_cycles_as_producer
      OrderCycle.
        preload(:schedules).
        ransack(raw_params[:q]).
        result.
        involving_managed_producers_of(spree_current_user).
        order('updated_at DESC')
    end

    def order_cycles_as_both
      OrderCycle.
        preload(:schedules).
        ransack(raw_params[:q]).
        result.
        visible_by(spree_current_user)
    end

    def load_data_for_index
      if json_request?
        # Split ransack params into all those that currently exist and new ones
        #   to limit returned ocs to recent or undated
        orders_close_at_gt = raw_params[:q].andand.delete(:orders_close_at_gt) || 31.days.ago
        raw_params[:q] = {
          g: [raw_params.delete(:q) || {}, { m: 'or',
                                             orders_close_at_gt: orders_close_at_gt,
                                             orders_close_at_null: true }]
        }
        @collection = collection
      end
    end

    def require_coordinator
      @order_cycle.coordinator =
        permitted_coordinating_enterprises_for(@order_cycle).find_by(id: params[:coordinator_id])
      return if params[:coordinator_id] && @order_cycle.coordinator

      available_coordinators = permitted_coordinating_enterprises_for(@order_cycle)
      case available_coordinators.count
      when 0
        flash[:error] = I18n.t(:order_cycles_no_permission_to_coordinate_error)
        redirect_to main_app.admin_order_cycles_path
      when 1
        @order_cycle.coordinator = available_coordinators.first
      else
        if params[:coordinator_id]
          flash[:error] = I18n.t(:order_cycles_no_permission_to_create_error)
        end
        render :set_coordinator
      end
    end

    def protect_invalid_destroy
      # Can't delete if OC is linked to any orders or schedules
      if @order_cycle.schedules.any?
        redirect_to main_app.admin_order_cycles_url
        flash[:error] = I18n.t('admin.order_cycles.destroy_errors.schedule_present')
      else
        begin
          yield
        rescue ActiveRecord::InvalidForeignKey
          redirect_to main_app.admin_order_cycles_url
          flash[:error] = I18n.t('admin.order_cycles.destroy_errors.orders_present')
        end
      end
    end

    def remove_protected_attrs
      return if order_cycle_params.blank?

      order_cycle_params.delete :coordinator_id

      unless Enterprise.managed_by(spree_current_user).include?(@order_cycle.coordinator)
        order_cycle_params.delete_if do |k, _v|
          [:name, :orders_open_at, :orders_close_at].include? k.to_sym
        end
      end
    end

    def authorized_order_cycles
      managed_ids = managed_enterprises.map(&:id)

      (order_cycle_bulk_params[:collection_attributes] || []).keep_if do |_index, hash|
        order_cycle = OrderCycle.find(hash[:id])
        managed_ids.include?(order_cycle.andand.coordinator_id)
      end
    end

    def order_cycles_from_set
      return if authorized_order_cycles.blank?

      OrderCycle.where(id: authorized_order_cycles.map{ |_k, v| v[:id] })
    end

    def order_cycle_set
      @order_cycle_set ||= Sets::OrderCycleSet.new(@order_cycles, order_cycle_bulk_params)
    end

    def require_order_cycle_set_params
      return if params[:order_cycle_set].present?

      render json: { errors: t('admin.order_cycles.bulk_update.no_data') },
             status: :unprocessable_entity
    end

    def ams_prefix_whitelist
      [:basic, :index]
    end

    def order_cycle_params
      @order_cycle_params ||= PermittedAttributes::OrderCycle.new(params).call.
        to_h.with_indifferent_access
    end

    def order_cycle_bulk_params
      params.require(:order_cycle_set).permit(
        collection_attributes: [:id] + PermittedAttributes::OrderCycle.basic_attributes
      ).to_h.with_indifferent_access
    end
  end
end
