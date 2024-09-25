# frozen_string_literal: true

class BackorderMailer < ApplicationMailer
  include I18nHelper

  def backorder_failed(order, linked_variants)
    @order = order
    @linked_variants = linked_variants

    I18n.with_locale valid_locale(order.distributor.owner) do
      mail(to: order.distributor.owner.email)
    end
  end
end
