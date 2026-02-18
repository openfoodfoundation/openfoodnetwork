# frozen_string_literal: true

require "flipper"
require "flipper/adapters/active_record"
require "open_food_network/feature_toggle"

Rails.application.configure do
  # Disable Flipper's built-in test helper.
  # It fails in CI and feature don't get activated.
  config.flipper.test_help = false
end

Flipper.configure do |flipper|
  # Still use recommended test setup with faster memory adapter:
  if Rails.env.test?
    # Use a shared Memory adapter for all tests. The adapter is instantiated
    # outside of the block so the same instance is returned in new threads.
    adapter = Flipper::Adapters::Memory.new
    flipper.adapter { adapter }
  end
end

# Groups
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end
Flipper.register(:new_2024_07_03) do |actor|
  actor.respond_to?(:created_at?) && actor.created_at >= Time.zone.parse("2024-07-03")
end

Flipper.register(:enterprise_with_no_inventory) do |actor|
  # This group applies to enterprises only, so we return false if the actor is not an Enterprise
  next false unless actor.actor.instance_of? Enterprise

  # Uses 2025-08-11 as filter because variant tag did not exist before that, enterprise created
  # after never had access to the inventory
  enterprise_with_variant_override = Enterprise
    .where(id: VariantOverride.joins(:hub).select(:hub_id))
    .where(created_at: ..."2025-08-11")
    .distinct
  enterprise_with_no_variant_override = Enterprise
    .where.not(id: enterprise_with_variant_override)

  enterprise_with_no_variant_override.exists?(actor.id)
end

Flipper.register(:enterprise_with_inventory) do |actor|
  # This group applies to enterprises only, so we return false if the actor is not an Enterprise
  next false unless actor.actor.instance_of? Enterprise

  # Uses 2025-08-11 as filter because variant tag did not exist before that, enterprise created
  # after never had access to the inventory
  enterprise_with_variant_override = Enterprise
    .where(id: VariantOverride.joins(:hub).select(:hub_id))
    .where(created_at: ..."2025-08-11")
    .distinct

  # Entperprise with inventory and with variant tag not manually enabled.
  enterprise_with_variant_override.exists?(actor.id) && !Flipper.enabled?(:variant_tag, actor)
end

Flipper::UI.configure do |config|
  config.descriptions_source = ->(_keys) do
    # return has to be hash of {String key => String description}
    OpenFoodNetwork::FeatureToggle::CURRENT_FEATURES
  end

  # Defaults to false. Set to true to show feature descriptions on the list
  # page as well as the view page.
  # config.show_feature_description_in_list = true

  if Rails.env.production?
    config.banner_text = <<~TEXT
      ⚠️ Production environment: be aware that the changes have an impact on the
      application. Please read the how-to before:
      https://github.com/openfoodfoundation/openfoodnetwork/wiki/Feature-toggles
    TEXT
    config.banner_class = 'danger'
  end
end

# Add known feature toggles. This may fail if the database isn't setup yet.
begin
  OpenFoodNetwork::FeatureToggle.setup!
rescue ActiveRecord::StatementInvalid
  nil
end
