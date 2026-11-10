# frozen_string_literal: true

# Tell ApiLogger who is making the current API request, so ApiLog records who made it.
module RecordApiUser
  extend ActiveSupport::Concern

  private

  # Anonymous requests get an unsaved Spree::User, and a request with an invalid key never
  # gets here because authentication halts the callback chain: both are logged with no user.
  def record_api_user
    user = api_user_for_logging
    return unless user.is_a?(Spree::User) && user.persisted?

    request.env[::ApiLogger::USER_ID_KEY] = user.id
  end

  # The user to log, for controllers where it isn't `current_api_user`.
  def api_user_for_logging
    current_api_user
  end
end
