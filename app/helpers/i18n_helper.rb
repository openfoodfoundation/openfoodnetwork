module I18nHelper
  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
