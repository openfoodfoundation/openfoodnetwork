# frozen_string_literal: true

class UserLocaleSetter
  def initialize(current_user, params_locale, cookies)
    @current_user = current_user
    @params_locale = params_locale
    @cookies = cookies
  end

  def call
    save_locale_from_params
    save_locale_from_cookies

    I18n.locale = valid_current_locale
  end

  def self.ensure_valid_locale_persisted(user)
    return unless user && !available_locale?(user.locale)

    user.update!(locale: I18n.default_locale)
  end

  def self.valid_locale_for_user(user)
    if user.andand.locale.present? && available_locale?(user.locale)
      user.locale
    else
      I18n.default_locale
    end
  end

  def self.available_locale?(locale)
    Rails.application.config.i18n.available_locales.include?(locale)
  end

  private

  attr_reader :current_user, :params_locale, :cookies

  def save_locale_from_params
    return unless params_locale && available_locale?(params_locale)

    current_user&.update!(locale: params_locale)
    cookies[:locale] = params_locale
  end

  def save_locale_from_cookies
    # If the user account has a selected locale: we ignore the locale set in cookies,
    # which is persisted per-device but not per-user.
    return unless current_user_locale.nil? && cookies[:locale] &&
                  available_locale?(cookies[:locale])

    current_user&.update!(locale: cookies[:locale])
  end

  def available_locale?(locale)
    self.class.available_locale?(locale)
  end

  def current_user_locale
    current_user.andand.locale
  end

  def valid_current_locale
    if current_user_locale && available_locale?(current_user_locale)
      current_user_locale
    elsif cookies[:locale] && available_locale?(cookies[:locale])
      cookies[:locale]
    else
      I18n.default_locale
    end
  end
end
