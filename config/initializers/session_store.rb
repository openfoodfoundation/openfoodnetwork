# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")

# Cookie domain is not set, to ensure it is "host-only". This avoids conflicting cookies between the
# root domain and subdomains (staging vs prod).

# Sessions older than 30 days are removed server-side by the trim_sessions scheduled job
# in config/sidekiq_scheduler.yml (configurable via SESSION_DAYS_TRIM_THRESHOLD env var).
# Note: ActiveRecord::SessionStore does not enforce expire_after server-side (it only sets the
# cookie's Expires header), so the trim job is what actually expires inactive sessions.
Openfoodnetwork::Application.config.session_store(
  :active_record_store,
  key: "_h-ofn_session_id"
)
