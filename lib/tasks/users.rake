require 'csv'

namespace :openfoodnetwork do

  namespace :dev do
    desc 'export users to CSV'
    task export_users: :environment do
      CSV.open('db/users.csv', 'wb') do |csv|
        csv << header
        # Skip some spambot users
        users = Spree::User.all.reject { |u| u.email =~ /example.net/ }
        users.each do |user|
          csv << row(user)
        end
      end
    end


    desc 'import users from CSV'
    task import_users: :environment do
      ActionMailer::Base.delivery_method = :test

      CSV.foreach('db/users.csv') do |row|
        next if row[0] == 'encrypted_password'

        create_user_from row
      end
    end


    private

    def header
      ["encrypted_password", "password_salt", "email", "remember_token", "persistence_token", "reset_password_token", "perishable_token", "sign_in_count", "failed_attempts", "last_request_at", "current_sign_in_at", "last_sign_in_at", "current_sign_in_ip", "last_sign_in_ip", "login", "created_at", "updated_at", "authentication_token", "unlock_token", "locked_at", "remember_created_at", "reset_password_sent_at",

       "role_name",

       "ship_address_firstname", "ship_address_lastname", "ship_address_address1", "ship_address_address2", "ship_address_city", "ship_address_zipcode", "ship_address_phone", "ship_address_state", "ship_address_country", "ship_address_created_at", "ship_address_updated_at", "ship_address_company", "ship_address_latitude", "ship_address_longitude",

       "bill_address_firstname", "bill_address_lastname", "bill_address_address1", "bill_address_address2", "bill_address_city", "bill_address_zipcode", "bill_address_phone", "bill_address_state", "bill_address_country", "bill_address_created_at", "bill_address_updated_at", "bill_address_company", "bill_address_latitude", "bill_address_longitude"]
    end


    def row(user)
      # sa = user.ship_address
      # ba = user.bill_address

      [user.encrypted_password, user.password_salt, user.email, user.remember_token, user.persistence_token, user.reset_password_token, user.perishable_token, user.sign_in_count, user.failed_attempts, user.last_request_at, user.current_sign_in_at, user.last_sign_in_at, user.current_sign_in_ip, user.last_sign_in_ip, user.login, user.created_at, user.updated_at, user.authentication_token, user.unlock_token, user.locked_at, user.remember_created_at, user.reset_password_sent_at,

       user.spree_roles.first.andand.name]

       # sa.andand.firstname, sa.andand.lastname, sa.andand.address1, sa.andand.address2, sa.andand.city, sa.andand.zipcode, sa.andand.phone, sa.andand.state, sa.andand.country, sa.andand.created_at, sa.andand.updated_at, sa.andand.company, sa.andand.latitude, sa.andand.longitude,

       # ba.andand.firstname, ba.andand.lastname, ba.andand.address1, ba.andand.address2, ba.andand.city, ba.andand.zipcode, ba.andand.phone, ba.andand.state, ba.andand.country, ba.andand.created_at, ba.andand.updated_at, ba.andand.company, ba.andand.latitude, ba.andand.longitude]
    end


    def create_user_from(row)
      user = Spree::User.create!({password: 'changeme123', password_confirmation: 'changeme123', email: row[2], remember_token: row[3], persistence_token: row[4], reset_password_token: row[5], perishable_token: row[6], sign_in_count: row[7], failed_attempts: row[8], last_request_at: row[9], current_sign_in_at: row[10], last_sign_in_at: row[11], current_sign_in_ip: row[12], last_sign_in_ip: row[13], login: row[14], created_at: row[15], updated_at: row[16], authentication_token: row[17], unlock_token: row[18], locked_at: row[19], remember_created_at: row[20], reset_password_sent_at: row[21]}, without_protection: true)

      user.update_column :encrypted_password, row[0]
      user.update_column :password_salt, row[1]

      role = Spree::Role.find_by_name row[24]
      user.spree_roles << role if role
    rescue ActiveRecord::RecordInvalid => e
      puts "#{row[2]} - #{e.message}"
    end
  end
end
