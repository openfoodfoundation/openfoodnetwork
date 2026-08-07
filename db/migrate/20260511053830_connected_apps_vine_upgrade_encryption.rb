# frozen_string_literal: true

class ConnectedAppsVineUpgradeEncryption < ActiveRecord::Migration[7.1]
  class ConnectedApp < ActiveRecord::Base
    # This prevent rails from detecting the single table inheritance, so it won't try to load
    # ConnectedApps::Vine model
    self.inheritance_column = "this_column_doesnt_exist"

    encrypts :data
  end

  def up
    # This will decrypt existing encrypted data and re encrypt it with the new configured
    # hash: SHA-256
    ConnectedApp.where(type: "ConnectedApps::Vine").find_each(&:encrypt)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
