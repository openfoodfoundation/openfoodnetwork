# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")

# Cookie domain is not set, to ensure it is "host-only". This avoids conflicting cookies between the
# root domain and subdomains (staging vs prod).

# Inactive sessions expire after roughly a month through two complementary layers:
#   1. expire_after sets the cookie's Expires header, so a compliant browser stops sending the
#      cookie after a month of inactivity (client-side; refreshed on each response).
#   2. The trim_sessions scheduled job (config/sidekiq_scheduler.yml) deletes session records
#      older than 30 days server-side (configurable via SESSION_DAYS_TRIM_THRESHOLD).
# Note: ActiveRecord::SessionStore does NOT enforce expire_after server-side (it only sets the
# cookie header), so the trim job is what authoritatively expires sessions; expire_after is
# defence-in-depth on the client.
Openfoodnetwork::Application.config.session_store(
  :active_record_store,
  key: "_h-ofn_session_id",
  expire_after: 1.month
)
