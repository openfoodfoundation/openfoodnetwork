# frozen_string_literal: true

class WebhookEndpointsController < ::BaseController
  before_action :load_resource, only: :destroy

  def create
    webhook_endpoint = spree_current_user.webhook_endpoints.new(webhook_endpoint_params)

    if webhook_endpoint.save
      flash[:success] = t('.success')
    else
      flash[:error] = t('.error')
    end

    redirect_to redirect_path
  end

  def destroy
    if @webhook_endpoint.destroy
      flash[:success] = t('.success')
    else
      flash[:error] = t('.error')
    end

    redirect_to redirect_path
  end

  def load_resource
    @webhook_endpoint = spree_current_user.webhook_endpoints.find(params[:id])
  end

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(:url)
  end

  def redirect_path
    if request.referer.blank? || request.referer.include?(spree.account_path)
      developer_settings_path
    else
      request.referer
    end
  end

  def developer_settings_path
    "#{spree.account_path}#/developer_settings"
  end
end
