# frozen_string_literal: true

module OrderErrorHandling
  extend ActiveSupport::Concern

  private

  def render_error
    flash.now[:error] ||= I18n.t(
      'split_checkout.errors.saving_failed',
      messages: order_error_messages
    )

    render status: :unprocessable_entity, cable_ready: cable_car.
      replace("#checkout", partial("split_checkout/checkout")).
      replace("#flashes", partial("shared/flashes", locals: { flashes: flash }))
  end

  def order_error_messages
    # Remove ship_address.* errors if no shipping method is not selected
    remove_ship_address_errors if no_ship_address_needed?

    # Reorder errors to make sure the most important ones are shown first
    # and finally, return the error messages to sentence
    reorder_errors.map(&:full_message).to_sentence
  end

  def reorder_errors
    @order.errors.sort_by do |e|
      case e.attribute
      when /email/i then 0
      when /phone/i then 1
      when /bill_address/i then 2 + bill_address_error_order(e)
      else 20
      end
    end
  end
end
