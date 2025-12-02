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

  def test # rubocop:disable Metrics/MethodLength
    at = Time.zone.now
    test_payload = {
      payment: {
        updated_at: at,
        amount: 0.00,
        state: "completed"
      },
      enterprise: {
        abn: "65797115831",
        acn: "",
        name: "TEST Enterprise",
        address: {
          address1: "1 testing street",
          address2: "",
          city: "TestCity",
          zipcode: "1234"
        }
      },
      order: {
        total: 0.00,
        currency: "AUD",
        line_items: [
          {
            quantity: 1,
            price: 20.00,
            tax_category_name: "VAT",
            product_name: "Test product",
            name_to_display: "",
            unit_to_display: "1kg"
          }
        ]
      }
    }

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
