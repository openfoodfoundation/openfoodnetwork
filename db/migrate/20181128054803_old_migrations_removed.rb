# frozen_string_literal: true

class OldMigrationsRemoved < ActiveRecord::Migration[4.2]
  def up
    raise StandardError, <<-MESSAGE

      You haven't updated your dev environment in a long time!
      Legacy migration files before 2019 have now been removed.
      Run `rake db:schema:load` before running `rake db:migrate`.

    MESSAGE
  end
end
