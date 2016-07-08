require 'open_food_network/permissions'

module Admin
  class SchedulesController < ResourceController

    respond_override create: { json: {
      success: lambda {
        binding.pry
        render_as_json @schedule, editable_schedule_ids: permissions.editable_schedules.pluck(:id)
      },
      failure: lambda { render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity }
    } }


    def index
      respond_to do |format|
        format.json do
          render_as_json @collection, ams_prefix: params[:ams_prefix], editable_schedule_ids: permissions.editable_schedules.pluck(:id)
        end
      end
    end

    private
    def collection
      return Schedule.where("1=0") unless json_request?
      permissions.visible_schedules
    end

    def collection_actions
      [:index]
    end

    def permissions
      return @permissions unless @permission.nil?
      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end
  end
end
