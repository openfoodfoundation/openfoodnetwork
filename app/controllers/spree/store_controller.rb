class Spree::StoreController < Spree::BaseController
  layout 'darkswarm'

  include I18nHelper
  before_filter :set_locale

  def unauthorized
    render 'shared/unauthorized', status: :unauthorized
  end
end
