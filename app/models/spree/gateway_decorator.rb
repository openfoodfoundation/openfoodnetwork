Spree::Gateway.class_eval do
  # Default to live
  preference :server, :string, :default => 'live'
  preference :test_mode, :boolean, :default => false
end
