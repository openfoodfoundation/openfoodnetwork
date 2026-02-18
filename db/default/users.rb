# frozen_string_literal: true

def create_admin_user
  attributes = read_user_attributes

  admin = Spree::User.new(attributes)
  admin.skip_confirmation!
  admin.skip_confirmation_notification!

  # The default domain example.com is not resolved by all nameservers.
  ValidEmail2::Address.define_method(:valid_mx?) { true }

  if admin.save
    printf <<~TEXT
      New admin user persisted!
      Username: #{admin.email}
      Password: #{admin.password}
    TEXT
  else
    printf "There was some problems with persisting new admin user:\n"
    admin.errors.full_messages.each do |error|
      printf "#{error}\n"
    end
  end
end

def read_user_attributes
  password = ENV.fetch("ADMIN_PASSWORD", "ofn123")
  email = ENV.fetch("ADMIN_EMAIL", "ofn@example.com")

  {
    admin: true,
    password:,
    password_confirmation: password,
    email:,
    login: email
  }
end

create_admin_user if Spree::User.none?
