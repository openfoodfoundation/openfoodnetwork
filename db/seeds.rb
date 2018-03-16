# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
require 'yaml'

# -- Spree
unless Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
  puts "[db:seed] Seeding Spree"
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
  Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
end

country = Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
puts "Country is #{country.to_s}"

puts "[db:seed] loading states yaml"
states = YAML::load_file "db/default/spree/states.yml"
puts "States: #{states.to_s}"

# -- Seeding States
puts "[db:seed] Seeding states for " + country.name

states.each do |state|
  puts "State: " + state.to_s

  unless Spree::State.find_by_name(state['name'])
    Spree::State.create!(
      { name: state['name'], abbr: state['abbr'], country: country },
      without_protection: true
    )
  end
end

create_mail_method

def create_mail_method
  Spree::MailMethod.destroy_all

  CreateMailMethod.new(
    environment: Rails.env,
    preferred_enable_mail_delivery: true,
    preferred_mail_host: ENV['MAIL_HOST'],
    preferred_mail_domain: ENV['MAIL_DOMAIN'],
    preferred_mail_port: ENV['MAIL_PORT'],
    preferred_mail_auth_type: 'login',
    preferred_smtp_username: ENV['SMTP_USERNAME'],
    preferred_smtp_password: ENV['SMTP_PASSWORD'],
    preferred_secure_connection_type: 'None',
    preferred_mails_from: "no-reply@#{ENV['MAIL_DOMAIN']}",
    preferred_mail_bcc: '',
    preferred_intercept_email: ''
  ).call
end
