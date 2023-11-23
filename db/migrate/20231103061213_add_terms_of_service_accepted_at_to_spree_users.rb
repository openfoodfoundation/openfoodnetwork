class AddTermsOfServiceAcceptedAtToSpreeUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :spree_users, :terms_of_service_accepted_at, :datetime

    if Spree::Config.enterprises_require_tos == true
      # Update only user who are owners of at least 1 enterprise
      ActiveRecord::Base.sanitize_sql(["
         UPDATE spree_users
         SET terms_of_service_accepted_at = :time
         WHERE spree_users.id IN(
           SELECT id FROM spree_users WHERE EXISTS (
             SELECT 1 FROM enterprises WHERE spree_users.id = enterprises.owner_id
           )
        )".squish,
        time: Time.zone.now
      ])
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def down
   remove_column :spree_users, :terms_of_service_accepted_at
  end
end
