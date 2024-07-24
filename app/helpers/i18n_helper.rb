# frozen_string_literal: true

module I18nHelper
  def locale_options
    OpenFoodNetwork::I18nConfig.selectable_locales.map do |locale|
      [t('language_name', locale:), locale]
    end
  end

  def set_locale
    UserLocaleSetter.new(spree_current_user, params[:locale], cookies).set_locale
  end

  def valid_locale(user)
    UserLocaleSetter.new(user).valid_current_locale
  end
end
