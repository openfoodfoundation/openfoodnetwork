# frozen_string_literal: true

module Spree
  class ShipmentMailer < BaseMailer
    def shipped_email(shipment, resend = false)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '') + base_subject
      mail(to: @shipment.order.email, from: from_address, subject: subject)
    end

    private

    def base_subject
      "#{@shipment.order.distributor.name} #{default_i18n_subject} ##{@shipment.order.number}"
    end
  end
end
