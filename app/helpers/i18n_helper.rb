module I18nHelper
  def set_locale
    UserLocaleSetter.new(spree_current_user, params[:locale], cookies).set_locale
  end

  def valid_locale(user)
    UserLocaleSetter.new(user).valid_locale_for_user
  end
end
