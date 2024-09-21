# frozen_string_literal: true

class SubscriptionMailer < ApplicationMailer
  helper 'checkout'
  helper MailerHelper
  helper ShopMailHelper
  helper OrderHelper
  helper Spree::PaymentMethodsHelper
  include I18nHelper

  def confirmation_email(order)
    @type = 'confirmation'
    @order = order
    @hide_ofn_navigation = @order.distributor.hide_ofn_navigation
    I18n.with_locale valid_locale(@order.user) do
      subject = t('.subject',
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: @order.email,
           subject:,
           reply_to: @order.distributor.contact.email)
    end
  end

  def empty_email(order, changes)
    @type = 'empty'
    @changes = changes
    @order = order
    @hide_ofn_navigation = @order.distributor.hide_ofn_navigation
    I18n.with_locale valid_locale(@order.user) do
      subject = t('.subject',
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: @order.email,
           subject:,
           reply_to: @order.distributor.contact.email)
    end
  end

  def placement_email(order, changes)
    @type = 'placement'
    @changes = changes
    @order = order
    @hide_ofn_navigation = @order.distributor.hide_ofn_navigation
    I18n.with_locale valid_locale(@order.user) do
      subject = t('.subject',
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: @order.email,
           subject:,
           reply_to: @order.distributor.contact.email)
    end
  end

  def failed_payment_email(order)
    @order = order
    @hide_ofn_navigation = @order.distributor.hide_ofn_navigation
    I18n.with_locale valid_locale(@order.user) do
      subject = t('.subject',
                  number: @order.number,
                  distributor: @order.distributor.name)
      mail(to: @order.email,
           subject:,
           reply_to: @order.distributor.contact.email)
    end
  end

  def placement_summary_email(summary)
    @shop = Enterprise.find(summary.shop_id)
    @summary = summary
    I18n.with_locale valid_locale(@shop.owner) do
      subject = t('.subject',
                  distributor: @shop.name)
      mail(to: @shop.contact.email,
           subject:)
    end
  end

  def confirmation_summary_email(summary)
    @shop = Enterprise.find(summary.shop_id)
    @summary = summary
    I18n.with_locale valid_locale(@shop.owner) do
      subject = t('.subject',
                  distributor: @shop.name)
      mail(to: @shop.contact.email,
           subject:)
    end
  end
end
