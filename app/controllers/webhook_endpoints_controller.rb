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
    event, payload = test_delivery

    if event
      WebhookDeliveryJob.perform_later(@webhook_endpoint.url, event, payload, at: Time.zone.now)
      flash[:success] = t(".success")
    else
      flash[:error] = t(".unsupported")
    end

    respond_with do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          :flashes, partial: "shared/flashes", locals: { flashes: flash }
        )
      end
    end
  end

  private

  # The event and payload to preview, for the webhook types we can describe.
  def test_delivery
    case @webhook_endpoint.webhook_type
    when "payment_status_changed"
      ["payment.completed", Payments::WebhookPayload.test_data.to_hash]
    when "order_payment_due"
      ["order.payment_due", Orders::WebhookPayload.test_data.to_hash]
    end
  end

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
