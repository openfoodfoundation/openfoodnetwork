class RemoveGaCookiesPreference < ActiveRecord::Migration[4.2]
  class Spree::Preference < ActiveRecord::Base; end

  def up
    Spree::Preference
      .where( key: 'spree/app_configuration/cookies_policy_ga_section')
      .destroy_all
  end

  def down
    # If this preference is re-added to the code, the DB entry will be regenerated
  end
end
