# Be sure to restart your server when you modify this file.

# The cookie_store can be too small for very long URLs stored by Devise.
# The maximum size of cookies is 4096 bytes.
#Openfoodnetwork::Application.config.session_store :cookie_store, key: '_openfoodnetwork_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
Openfoodnetwork::Application.config.session_store :active_record_store
