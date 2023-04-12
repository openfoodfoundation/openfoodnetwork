# frozen_string_literal: true

require 'devise/mailers/helpers'
class EnterpriseMailer < ApplicationMailer
  include Devise::Mailers::Helpers
  include I18nHelper

  def welcome(enterprise)
    @enterprise = enterprise
    I18n.with_locale valid_locale(@enterprise.owner) do
      subject = t('enterprise_mailer.welcome.subject',
                  enterprise: @enterprise.name,
                  sitename: Spree::Config[:site_name])
      mail(to: enterprise.contact.email,
           subject: subject)
    end
  end

  def manager_invitation(enterprise, user)
    @enterprise = enterprise
    @instance = Spree::Config[:site_name]

    I18n.with_locale valid_locale(@enterprise.owner) do
      subject = t('enterprise_mailer.invite_manager.subject', enterprise: @enterprise.name)
      mail(to: user.email,
           subject: subject)
    end
  end

  private

  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
