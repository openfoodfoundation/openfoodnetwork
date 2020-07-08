# frozen_string_literal: true

class UserLocaleSetter
  def initialize(current_user, params_locale = nil, cookies = {})
    @current_user = current_user
    @params_locale = params_locale
    @cookies = cookies
  end

  def set_locale
    save_locale_from_params

    I18n.locale = valid_current_locale
  end

  def ensure_valid_locale_persisted
    return unless current_user && !available_locale?(current_user.locale)

    current_user.update!(locale: valid_current_locale)
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

  private

  attr_reader :current_user, :params_locale, :cookies

  def save_locale_from_params
    return unless params_locale && available_locale?(params_locale)

    current_user&.update!(locale: params_locale)
    cookies[:locale] = params_locale
  end

  def available_locale?(locale)
    Rails.application.config.i18n.available_locales.include?(locale)
  end

  def current_user_locale
    current_user&.locale
  end
end
