# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).
require 'yaml'

# We need mail_configuration to create a user account, because it sends a confirmation email.
MailConfiguration.apply!

Rails.logger.info "[db:seed] Seeding Countries"
unless Spree::Country.find_by(iso: ENV.fetch('DEFAULT_COUNTRY_CODE', nil))
  require File.join(File.dirname(__FILE__), 'default', 'countries')
end
country = Spree::Country.find_by(iso: ENV.fetch('DEFAULT_COUNTRY_CODE', nil))
Rails.logger.info { "Default country is #{country}" }

Rails.logger.info { "[db:seed] Seeding states for #{country.name}" }
states = YAML.load_file "db/default/spree/states.yml"
states.each do |state|
  Rails.logger.info { "State: #{state}" }
  unless Spree::State.find_by(name: state['name'])
    Spree::State.create!({ name: state['name'], abbr: state['abbr'], country: })
  end
end

Rails.logger.info "[db:seed] Seeding Zones"
require File.join(File.dirname(__FILE__), 'default', 'zones')

Rails.logger.info "[db:seed] Seeding Users"
require File.join(File.dirname(__FILE__), 'default', 'users')

DefaultShippingCategory.find_or_create
