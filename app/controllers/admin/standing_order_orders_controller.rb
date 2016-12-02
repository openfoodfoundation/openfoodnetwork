module Admin
  class StandingOrderOrdersController < ResourceController
    respond_to :json

    def cancel
      if @standing_order_order.cancel
        respond_with(@standing_order_order) do |format|
          format.json { render_as_json @standing_order_order }
        end
      else
        respond_with(@standing_order_order) do |format|
          format.json { render json: { errors: [t(:could_not_cancel_the_order)] }, status: :unprocessable_entity }
        end
      end
    end

    def resume
      if @standing_order_order.resume
        respond_with(@standing_order_order) do |format|
          format.json { render_as_json @standing_order_order }
        end
      else
        respond_with(@standing_order_order) do |format|
          format.json { render json: { errors: [t(:could_not_resume_the_order)] }, status: :unprocessable_entity }
        end
      end
    end
  end
end
