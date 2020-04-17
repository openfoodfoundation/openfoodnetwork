class OldMigrationsRemoved < ActiveRecord::Migration
  def up
    raise StandardError, <<-MESSAGE

      You haven't updated your dev environment in a long time!
      Legacy migration files before 2019 have now been removed.
      Run `rails db:schema:load` before running `rails db:migrate`.

    MESSAGE
  end
end
