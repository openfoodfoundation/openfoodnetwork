module I18nHelper
  def set_locale
    UserLocaleSetter.new(spree_current_user, params[:locale], cookies).call
  end

  def valid_locale(user)
    UserLocaleSetter.valid_locale_for_user(user)
  end
end
