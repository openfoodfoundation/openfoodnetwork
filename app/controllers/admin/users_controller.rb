# frozen_string_literal: true

module Admin
  class UsersController < Spree::Admin::BaseController
    def accept_terms_of_service
      spree_current_user.update(terms_of_service_accepted_at: DateTime.now)

      respond_to do |format|
        format.turbo_stream
        format.html { render body: nil }
      end
    end
  end
end
