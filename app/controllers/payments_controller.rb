# frozen_string_literal: true

class PaymentsController < BaseController
  respond_to :html

  prepend_before_action :require_logged_in, only: :redirect_to_authorize

  def redirect_to_authorize
    @payment = Spree::Payment.find(params[:id])
    authorize! :show, @payment.order

    if (url = @payment.cvv_response_message)
      redirect_to url
    else
      redirect_to order_url(@payment.order)
    end
  end

  private

  def require_logged_in
    return if session[:access_token] || spree_current_user

    store_location_for :spree_user, request.original_fullpath

    flash[:error] = I18n.t("spree.orders.edit.login_to_view_order")
    redirect_to main_app.root_path(anchor: "/login", after_login: request.original_fullpath)
  end
end
