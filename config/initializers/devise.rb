Devise.setup do |config|
  # Add a default scope to devise, to prevent it from checking
  # whether other devise enabled models are signed into a session or not
  config.default_scope = :spree_user
  config.omniauth :facebook, "APP ID", "APP SECRET"
    # callback_url: "CALLBACK_URL"
end