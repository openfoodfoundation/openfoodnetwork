# frozen_string_literal: true

class BackorderMailer < ApplicationMailer
  include I18nHelper

  def backorder_failed(order)
    @order = order
    @linked_variants = order.variants

    I18n.with_locale valid_locale(order.distributor.owner) do
      mail(to: order.distributor.owner.email)
    end
  end

  def backorder_incomplete(user, distributor, order_cycle, order_id)
    @distributor = distributor
    @order_cycle = order_cycle
    @order_id = order_id

    I18n.with_locale valid_locale(user) do
      mail(to: user.email)
    end
  end
end
