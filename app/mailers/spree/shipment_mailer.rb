# frozen_string_literal: true

module Spree
  class ShipmentMailer < ApplicationMailer
    include I18nHelper
    helper MailerHelper
    helper 'checkout'

    def shipped_email(shipment, delivery:)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      @order = @shipment.order
      @hide_ofn_navigation = @shipment.order.distributor.hide_ofn_navigation
      @delivery = delivery
      I18n.with_locale valid_locale(@order.user) do
        subject = t(base_subject,
                    number: @order.number,
                    distributor: @order.distributor.name)
        mail(to: @shipment.order.email,
             subject:,
             reply_to: @order.distributor.contact.email)
      end
    end

    private

    def base_subject
      @delivery ? '.subject' : '.picked_up_subject'
    end
  end
end
