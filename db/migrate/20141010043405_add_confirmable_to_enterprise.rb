class AddConfirmableToEnterprise < ActiveRecord::Migration
  def up
    add_column :enterprises, :confirmation_token, :string
    add_column :enterprises, :confirmed_at, :datetime
    add_column :enterprises, :confirmation_sent_at, :datetime
    add_column :enterprises, :unconfirmed_email, :string
    add_index :enterprises, :confirmation_token, :unique => true

    # Existing enterprises are assumed to be confirmed
    Enterprise.update_all(:confirmed_at => Time.zone.now)
  end

  def down
    remove_columns :enterprises, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
