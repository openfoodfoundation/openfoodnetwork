# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks. 
Openfoodnetwork::Application.config.secret_token = if Rails.env.development? or Rails.env.test?
  ('x' * 30) # Meets basic minimum of 30 chars.
else
  ENV["SECRET_TOKEN"]
end

Openfoodnetwork::Application.config.secret_key_base = 'ceb1eb86c50285e696f899b2e7ea306d1ec1e81fe5c7af0e5cbc238bebe3fd60f19df7b9076fab836182821ebe14e41b64bdcdb4370520dc5bb711c1bc0ae616'
