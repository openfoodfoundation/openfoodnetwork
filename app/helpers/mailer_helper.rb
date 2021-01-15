# frozen_string_literal: true

module MailerHelper
  def footer_ofn_link
    ofn = I18n.t("shared.mailers.powered_by.open_food_network")

    if ContentConfig.footer_email.present?
      mail_to ContentConfig.footer_email, ofn
    else
      link_to ofn, "https://www.openfoodnetwork.org"
    end
  end
end
