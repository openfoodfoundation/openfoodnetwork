# frozen_string_literal: true

class LocalesController < BaseController
  def show
    UserLocaleSetter.new(spree_current_user, params[:id], cookies).set_locale
    redirect_back_or_to(main_app.root_url)
  end
end
