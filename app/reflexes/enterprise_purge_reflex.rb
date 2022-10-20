# frozen_string_literal: true

class EnterprisePurgeReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def logo
    @enterprise = Enterprise.find(element.dataset["enterprise-id"])
    ability = Spree::Ability.new(current_user).can? :remove_logo, @enterprise
    throw :forbidden unless ability
    @enterprise.logo.purge_later
    message = I18n.t('admin.enterprises.form.images.removed_logo_successfully')
    cable_ready.inner_html(selector: "#status-message",
                           html: message)
  end

  def promo_image
    @enterprise = Enterprise.find(element.dataset["enterprise-id"])
    ability = Spree::Ability.new(current_user).can? :remove_promo_image, @enterprise
    throw :forbidden unless ability
    @enterprise.promo_image.purge_later
    message = I18n.t('admin.enterprises.form.images.removed_promo_image_successfully')
    cable_ready.inner_html(selector: "#status-message",
                           html: message)
  end
end
