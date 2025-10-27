# frozen_string_literal: true

class ScheduleForm
  include ActiveModel::Model

  attr_reader :errors, :flash_success

  def initialize(params, user, schedule = nil)
    @errors = ActiveModel::Errors.new self

    # Not strong
    @params = params
    @current_user = user
    @schedule = schedule
  end

  def save
    editable_order_cycle_ids_for_create

    return false if @params[:order_cycle_ids].blank?

    @schedule.attributes = permitted_resource_params

    if @schedule.save
      @schedule.order_cycle_ids = @params[:order_cycle_ids]
      @schedule.save!

    end

    true
  end

  def update(_params)
    editable_order_cycle_ids_for_update

    false unless @schedule.update(permitted_resource_params)
  end

  delegate :order_cycle_ids, to: :@schedule

  private

  def editable_order_cycle_ids_for_create
    return unless @params[:order_cycle_ids]

    @existing_order_cycle_ids = []
    result = editable_order_cycles(@params[:order_cycle_ids])
    @params[:order_cycle_ids] = result
  end

  def editable_order_cycle_ids_for_update
    return unless @params[:schedule][:order_cycle_ids]

    @existing_order_cycle_ids = @schedule.order_cycle_ids
    result = editable_order_cycles(@params[:schedule][:order_cycle_ids])

    @params[:schedule][:order_cycle_ids] = result
    @schedule.order_cycle_ids = result
  end

  def editable_order_cycles(requested)
    permitted = OrderCycle
      .where(id: @params[:order_cycle_ids] | @existing_order_cycle_ids)
      .merge(OrderCycle.managed_by(@current_user))
      .pluck(:id)
    result = @existing_order_cycle_ids
    result |= (requested & permitted) # add any requested & permitted ids
    # remove any existing and permitted ids that were not specifically requested
    result -= ((result & permitted) - requested)
    result
  end

  def permitted_resource_params
    @params.require(:schedule).permit(:id, :name, order_cycle_ids: [])
  end
end
