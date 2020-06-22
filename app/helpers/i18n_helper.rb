module I18nHelper
  def set_locale
    # Save a given locale
    if params[:locale] && available_locale?(params[:locale])
      spree_current_user&.update!(locale: params[:locale])
      cookies[:locale] = params[:locale]
    end

    # After logging in, check if the user chose a locale before
    if spree_current_user && spree_current_user.locale.nil? && cookies[:locale]
      spree_current_user.update!(locale: params[:locale])
    end

    I18n.locale = spree_current_user.andand.locale || cookies[:locale] || I18n.default_locale
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
end
