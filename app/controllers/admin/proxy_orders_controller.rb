# frozen_string_literal: true

module Admin
  class ProxyOrdersController < Admin::ResourceController
    respond_to :json

    def edit
      @proxy_order.initialise_order! unless @proxy_order.order
      redirect_to spree.edit_admin_order_path(@proxy_order.order)
    end

    def cancel
      if @proxy_order.cancel
        render_as_json @proxy_order
      else
        render json: { errors: [t('admin.proxy_orders.cancel.could_not_cancel_the_order')] },
               status: :unprocessable_entity
      end
    end

    def resume
      if @proxy_order.resume
        render_as_json @proxy_order
      else
        render json: { errors: [t('admin.proxy_orders.resume.could_not_resume_the_order')] },
               status: :unprocessable_entity
      end
    end
  end
end
