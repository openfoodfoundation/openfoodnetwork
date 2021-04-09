class DropMailMethods < ActiveRecord::Migration[4.2]
  def up
    drop_table :spree_mail_methods

    # delete mail_method preferences associated with the old MailMethod model
    execute "DELETE FROM spree_preferences WHERE key LIKE 'spree/mail_method%'"
  end

  def down
    create_table :spree_mail_methods do |t|
      t.string     :environment
      t.boolean    :active, default: true
      t.timestamps
    end
  end
end
