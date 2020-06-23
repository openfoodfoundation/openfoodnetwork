module Spree
  class StoreController < Spree::BaseController
    layout 'darkswarm'

    include Spree::Core::ControllerHelpers::Order

    include I18nHelper
    before_action :set_locale

    def unauthorized
      render 'shared/unauthorized', status: :unauthorized
    end
  end
end
