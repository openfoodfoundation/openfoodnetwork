Devise.setup do |config|
  # Add a default scope to devise, to prevent it from checking
  # whether other devise enabled models are signed into a session or not
  config.default_scope = :spree_user
end