# frozen_string_literal: true

module Spree
  class PaypalController < StoreController
    ssl_allowed

    def express
      order = current_order || raise(ActiveRecord::RecordNotFound)
      items = order.line_items.map(&method(:line_item))

      tax_adjustments = order.adjustments.tax
      # TODO: Remove in Spree 2.2
      tax_adjustments = tax_adjustments.additional if tax_adjustments.respond_to?(:additional)
      shipping_adjustments = order.adjustments.shipping

      order.adjustments.eligible.each do |adjustment|
        next if (tax_adjustments + shipping_adjustments).include?(adjustment)
        items << {
          :Name => adjustment.label,
          :Quantity => 1,
          :Amount => {
            :currencyID => order.currency,
            :value => adjustment.amount
          }
        }
      end

      # Because PayPal doesn't accept $0 items at all.
      # See #10
      # https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECCustomizing
      # "It can be a positive or negative value but not zero."
      items.reject! do |item|
        item[:Amount][:value].zero?
      end
      pp_request = provider.build_set_express_checkout(express_checkout_request_details(order, items))

      begin
        pp_response = provider.set_express_checkout(pp_request)
        if pp_response.success?
          redirect_to provider.express_checkout_url(pp_response, :useraction => 'commit')
        else
          flash[:error] = Spree.t('flash.generic_error', :scope => 'paypal', :reasons => pp_response.errors.map(&:long_message).join(" "))
          redirect_to checkout_state_path(:payment)
        end
      rescue SocketError
        flash[:error] = Spree.t('flash.connection_failed', :scope => 'paypal')
        redirect_to checkout_state_path(:payment)
      end
    end

    def confirm
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.payments.create!({
        :source => Spree::PaypalExpressCheckout.create({
          :token => params[:token],
          :payer_id => params[:PayerID]
        } ),
        :amount => order.total,
        :payment_method => payment_method
      } )
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        session[:order_id] = nil
        redirect_to completion_route(order)
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    def cancel
      flash[:notice] = Spree.t('flash.cancel', :scope => 'paypal')
      order = current_order || raise(ActiveRecord::RecordNotFound)
      redirect_to checkout_state_path(order.state, paypal_cancel_token: params[:token])
    end

    private

    def line_item(item)
      {
          :Name => item.product.name,
          :Number => item.variant.sku,
          :Quantity => item.quantity,
          :Amount => {
              :currencyID => item.order.currency,
              :value => item.price
          },
          :ItemCategory => "Physical"
      }
    end

    def express_checkout_request_details order, items
      { :SetExpressCheckoutRequestDetails => {
          :InvoiceID => order.number,
          :BuyerEmail => order.email,
          :ReturnURL => confirm_paypal_url(:payment_method_id => params[:payment_method_id], :utm_nooverride => 1),
          :CancelURL =>  cancel_paypal_url,
          :SolutionType => payment_method.preferred_solution.present? ? payment_method.preferred_solution : "Mark",
          :LandingPage => payment_method.preferred_landing_page.present? ? payment_method.preferred_landing_page : "Billing",
          :cppheaderimage => payment_method.preferred_logourl.present? ? payment_method.preferred_logourl : "",
          :NoShipping => 1,
          :PaymentDetails => [payment_details(items)]
      }}
    end

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def provider
      payment_method.provider
    end

    def payment_details items
      item_sum = items.sum { |i| i[:Quantity] * i[:Amount][:value] }
      # Would use tax_total here, but it can include "included" taxes as well.
      # For instance, tax_total would include the 10% GST in Australian stores.
      # A quick sum will get us around that little problem.
      # TODO: Remove additional check in 2.2
      tax_adjustments = current_order.adjustments.tax
      tax_adjustments = tax_adjustments.additional if tax_adjustments.respond_to?(:additional)
      tax_adjustments_total = tax_adjustments.sum(:amount)

      if item_sum.zero?
        # Paypal does not support no items or a zero dollar ItemTotal
        # This results in the order summary being simply "Current purchase"
        {
          :OrderTotal => {
            :currencyID => current_order.currency,
            :value => current_order.total
          }
        }
      else
        {
          :OrderTotal => {
            :currencyID => current_order.currency,
            :value => current_order.total
          },
          :ItemTotal => {
            :currencyID => current_order.currency,
            :value => item_sum
          },
          :ShippingTotal => {
            :currencyID => current_order.currency,
            :value => current_order.ship_total
          },
          :TaxTotal => {
            :currencyID => current_order.currency,
            :value => tax_adjustments_total,
          },
          :ShipToAddress => address_options,
          :PaymentDetailsItem => items,
          :ShippingMethod => "Shipping Method Name Goes Here",
          :PaymentAction => "Sale"
        }
      end
    end

    def address_options
      return {} unless address_required?

      {
          :Name => current_order.bill_address.try(:full_name),
          :Street1 => current_order.bill_address.address1,
          :Street2 => current_order.bill_address.address2,
          :CityName => current_order.bill_address.city,
          :Phone => current_order.bill_address.phone,
          :StateOrProvince => current_order.bill_address.state_text,
          :Country => current_order.bill_address.country.iso,
          :PostalCode => current_order.bill_address.zipcode
      }
    end

    def completion_route(order)
      order_path(order, :token => order.token)
    end

    def address_required?
      payment_method.preferred_solution.eql?('Sole')
    end
  end
end
