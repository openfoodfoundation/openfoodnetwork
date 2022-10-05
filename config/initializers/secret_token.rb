# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# Rails 4+ key for signing and encrypting cookies.
Openfoodnetwork::Application.config.secret_key_base = ENV["SECRET_TOKEN"]

# Legacy secret_token variable. This is still used directly for encryption.
Openfoodnetwork::Application.config.secret_token = ENV["SECRET_TOKEN"]
