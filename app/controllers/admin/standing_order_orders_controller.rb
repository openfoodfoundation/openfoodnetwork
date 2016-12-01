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
          format.json { render json: { errors: @standing_order_order.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end
  end
end
