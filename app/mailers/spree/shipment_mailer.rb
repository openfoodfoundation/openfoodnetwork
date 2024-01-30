# frozen_string_literal: true

module Spree
  class ShipmentMailer < ApplicationMailer
    helper MailerHelper

    def shipped_email(shipment, delivery:)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      @order = @shipment.order
      @hide_ofn_navigation = @shipment.order.distributor.hide_ofn_navigation
      @delivery = delivery
      subject = t(base_subject,
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: @shipment.order.email, subject:)
    end

    private

    def base_subject
      @delivery ? '.subject' : '.picked_up_subject'
    end
  end
end
