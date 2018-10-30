class Spree::StoreController
  layout 'darkswarm'

  include I18nHelper
  before_filter :set_locale

  def unauthorized
    render 'shared/unauthorized', :status => 401
  end
end
