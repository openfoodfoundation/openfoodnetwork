# frozen_string_literal: true

require "tasks/sample_data/logging"

module SampleData
  class CustomerFactory
    include Logging

    def create_samples(users)
      log "Creating customers"
      jane = users["Jane Customer"]
      maryse_shop = Enterprise.find_by(name: "Maryse's Private Shop")
      return if Customer.where(user_id: jane, enterprise_id: maryse_shop).exists?

      log "- #{jane.email}"
      Customer.create!(
        email: jane.email,
        user: jane,
        enterprise: maryse_shop
      )
    end
  end
end
