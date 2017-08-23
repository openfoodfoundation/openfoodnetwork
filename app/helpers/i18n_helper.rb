module I18nHelper
  def set_locale
    # Save a given locale
    if params[:locale] && Rails.application.config.i18n.available_locales.include?(params[:locale])
      spree_current_user.update_attributes!(locale: params[:locale]) if spree_current_user
      cookies[:locale] = params[:locale]
    end

    # After logging in, check if the user chose a locale before
    if spree_current_user && spree_current_user.locale.nil? && cookies[:locale]
      spree_current_user.update_attributes!(locale: params[:locale])
    end

    I18n.locale = spree_current_user.andand.locale || cookies[:locale] || I18n.default_locale
  end
end
