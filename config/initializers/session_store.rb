# Be sure to restart your server when you modify this file.

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")

# Cookie domain is not set, to ensure it is "host-only". This avoids conflicting cookies between the
# root domain and subdomains (staging vs prod).

Openfoodnetwork::Application.config.session_store(
  :active_record_store,
  key: "_ofn_session_id"
)
