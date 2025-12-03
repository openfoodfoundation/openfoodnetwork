# frozen_string_literal: true

class WebhookEndpointsController < BaseController
  before_action :load_resource, only: [:destroy, :test]

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

  def test
    at = Time.zone.now
    test_payload = Payments::WebhookPayload.test_data.to_hash

    WebhookDeliveryJob.perform_later(@webhook_endpoint.url, "payment.completed", test_payload, at:)

    flash[:success] = t(".success")
    respond_with do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          :flashes, partial: "shared/flashes", locals: { flashes: flash }
        )
      end
    end
  end

  private

  def load_resource
    @webhook_endpoint = spree_current_user.webhook_endpoints.find(params[:id])
  end

  def webhook_endpoint_params
    params.require(:webhook_endpoint).permit(:url, :webhook_type)
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
