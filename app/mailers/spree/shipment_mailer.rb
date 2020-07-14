# frozen_string_literal: true

module Spree
  class ShipmentMailer < BaseMailer
    def shipped_email(shipment, resend = false)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      base_subject = t('spree.shipment_mailer.shipped_email.subject')
      subject += "#{Spree::Config[:site_name]} #{base_subject} ##{@shipment.order.number}"
      mail(to: @shipment.order.email, from: from_address, subject: subject)
    end
  end
end
