# frozen_string_literal: true

class UserReflex < ApplicationReflex
  def accept_terms_of_services
    current_user.update(terms_of_service_accepted_at: DateTime.now)

    morph "#banner-container", ""
  end
end
