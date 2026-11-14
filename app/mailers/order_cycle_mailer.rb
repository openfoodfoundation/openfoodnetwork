# frozen_string_literal: true

class OrderCycleMailer < ApplicationMailer
  include I18nHelper

  def producer_selection_updated(order_cycle, producer)
    @order_cycle = order_cycle
    @producer = producer
    coordinator = order_cycle.coordinator

    I18n.with_locale valid_locale(coordinator.owner) do
      mail(to: coordinator.contact.email, reply_to: producer.contact.email)
    end
  end
end
