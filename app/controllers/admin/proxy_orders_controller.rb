module Admin
  class ProxyOrdersController < ResourceController
    respond_to :json

    def cancel
      if @proxy_order.cancel
        respond_with(@proxy_order) do |format|
          format.json { render_as_json @proxy_order }
        end
      else
        respond_with(@proxy_order) do |format|
          format.json { render json: { errors: [t(:could_not_cancel_the_order)] }, status: :unprocessable_entity }
        end
      end
    end

    def resume
      if @proxy_order.resume
        respond_with(@proxy_order) do |format|
          format.json { render_as_json @proxy_order }
        end
      else
        respond_with(@proxy_order) do |format|
          format.json { render json: { errors: [t(:could_not_resume_the_order)] }, status: :unprocessable_entity }
        end
      end
    end
  end
end
