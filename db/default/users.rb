require 'highline/import'

# see last line where we create an admin if there is none, asking for email and password
def prompt_for_admin_password
  if ENV['ADMIN_PASSWORD']
    password = ENV['ADMIN_PASSWORD'].dup
    say "Admin Password #{password}"
  else
    password = ask('Password [ofn123]: ') do |q|
      q.echo = false
      q.validate = /^(|.{5,40})$/
      q.responses[:not_valid] = 'Invalid password. Must be at least 5 characters long.'
      q.whitespace = :strip
    end
    password = 'ofn123' if password.blank?
  end

  password
end

def prompt_for_admin_email
  if ENV['ADMIN_EMAIL']
    email = ENV['ADMIN_EMAIL'].dup
    say "Admin User #{email}"
  else
    email = ask('Email [ofn@example.com]: ') do |q|
      q.echo = true
      q.whitespace = :strip
    end
    email = 'ofn@example.com' if email.blank?
  end

  email
end

def create_admin_user
  if ENV.fetch("AUTO_ACCEPT", true)
    password = ENV.fetch("ADMIN_PASSWORD", "ofn123").dup
    email = ENV.fetch("ADMIN_EMAIL", "ofn@example.com").dup
  else
    puts 'Create the admin user (press enter for defaults).'
    #name = prompt_for_admin_name unless name
    email = prompt_for_admin_email
    password = prompt_for_admin_password
  end
  attributes = {
    :password => password,
    :password_confirmation => password,
    :email => email,
    :login => email
  }

  load 'spree/user.rb'

  if Spree::User.find_by(email: email)
    say "\nWARNING: There is already a user with the email: #{email}, so no account changes were made.  If you wish to create an additional admin user, please run rake spree_auth:admin:create again with a different email.\n\n"
  else
    admin = Spree::User.new(attributes)
    admin.skip_confirmation!
    admin.skip_confirmation_notification!

    # The default domain example.com is not resolved by all nameservers.
    ValidEmail2::Address.define_method(:valid_mx?) { true }

    if admin.save
      role = Spree::Role.find_or_create_by(name: 'admin')
      admin.spree_roles << role
      say "New admin user persisted!"
    else
      say "There was some problems with persisting new admin user:"
      admin.errors.full_messages.each do |error|
        say error
      end
    end
  end
end

create_admin_user if Spree::User.admin.empty?
