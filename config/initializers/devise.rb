Devise.setup do |config|
  # Add a default scope to devise, to prevent it from checking
  # whether other devise enabled models are signed into a session or not
  config.default_scope = :spree_user
  config.omniauth :facebook, "929520317127867", "e5ce96dd9a3fca61e3d542cf42c5731f"
    # callback_url: "CALLBACK_URL"
end