class MigrateStripeConnectEnterpriseToStripeSca < ActiveRecord::Migration[6.1]
  def up
    execute "UPDATE spree_preferences SET key = replace( key, 'stripe_connect', 'stripe_sca') WHERE key LIKE '/spree/gateway/stripe_connect/'"
  end
end

