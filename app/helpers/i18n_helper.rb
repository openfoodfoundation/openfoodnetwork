module I18nHelper
  def set_locale
    # Save a given locale from params
    if params[:locale] && available_locale?(params[:locale])
      spree_current_user&.update!(locale: params[:locale])
      cookies[:locale] = params[:locale]
    end

    # After logging in, check if the user chose a locale before
    if current_user_locale.nil? && cookies[:locale] && available_locale?(params[:locale])
      spree_current_user&.update!(locale: params[:locale])
    end

    I18n.locale = current_user_locale || cookies[:locale] || I18n.default_locale
  end

  def valid_locale(user)
    if user.present? &&
       user.locale.present? &&
       available_locale?(user.locale)
      user.locale
    else
      I18n.default_locale
    end
  end

  private

  def available_locale?(locale)
    Rails.application.config.i18n.available_locales.include?(locale)
  end

  def current_user_locale
    spree_current_user.andand.locale
  end
end
