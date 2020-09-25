class SetTimezoneForAllEnterprises < ActiveRecord::Migration
  def change
    Enterprise::update_all(timezone: Time.zone.name)
  end
end
