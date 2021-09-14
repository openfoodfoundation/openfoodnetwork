class MigrateStripeConnectEnterpriseToStripeSca < ActiveRecord::Migration[6.1]
  def up
    execute "UPDATE spree_preferences SET key = replace( key, 'stripe_connect', 'stripe_sca') WHERE key like '/spree/gateway/stripe_connect/%'"

    Rails.cache.delete_if {|key, v| key =~ '/spree/gateway/stripe_connect/enterprise_id/' }
  end
end

