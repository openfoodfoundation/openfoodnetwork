# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class UserFactory
    include Logging

    def create_samples
      log "Creating users:"
      usernames.map { |name|
        create_user(name)
      }.to_h
    end

    private

    def usernames
      [
        "Manel Super Admin",
        "Penny Profile",
        "Fred Farmer",
        "Freddy Shop Farmer",
        "Fredo Hub Farmer",
        "Mary Retailer",
        "Maryse Private",
        "Jane Customer"
      ]
    end

    def create_user(name)
      email = "#{name.downcase.tr(' ', '.')}@example.org"
      password = Spree::User.friendly_token
      log "- #{email}"
      user = Spree::User.create_with(
        password: password,
        password_confirmation: password,
        confirmation_sent_at: Time.zone.now,
        confirmed_at: Time.zone.now
      ).find_or_create_by!(email: email)
      [name, user]
    end
  end
end
