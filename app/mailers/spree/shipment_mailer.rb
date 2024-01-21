# frozen_string_literal: true

module Spree
  class ShipmentMailer < ApplicationMailer
    helper MailerHelper

    def shipped_email(shipment, delivery:)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      @order = @shipment.order
      @hide_ofn_navigation = @shipment.order.distributor.hide_ofn_navigation
      @delivery = delivery
      subject = base_subject
      mail(to: @shipment.order.email, subject:)
    end

    private

    def base_subject
      default_subject = @delivery ? default_i18n_subject : t('.picked_up_subject')
      "#{@shipment.order.distributor.name} #{default_subject} ##{@shipment.order.number}"
    end
  end
end
