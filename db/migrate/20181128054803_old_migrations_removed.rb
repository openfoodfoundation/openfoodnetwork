class OldMigrationsRemoved < ActiveRecord::Migration
  LAST_DELETED_MIGRATION = 20181128054803
  def up
    if ActiveRecord::Migrator.current_version < LAST_DELETED_MIGRATION
      message = "You haven't updated your dev environment in a long time! " \
                "Legacy migration files before 2019 have now been removed. " \
                "Run `rails db:schema:load` before running `rails db:migrate`."
      raise StandardError, message
    end
  end
end
