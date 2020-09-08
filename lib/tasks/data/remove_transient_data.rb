# frozen_string_literal: true

class RemoveTransientData
  RETENTION_PERIOD = 6.months.ago.to_date

  # This model lets us operate on the sessions DB table using ActiveRecord's
  # methods within the scope of this service. This relies on the AR's
  # convention where a Session model maps to a sessions table.
  class Session < ActiveRecord::Base
  end

  def call
    Rails.logger.info("#{self.class.name}: processing")

    Spree::StateChange.where("created_at < ?", RETENTION_PERIOD).delete_all
    Spree::LogEntry.where("created_at < ?", RETENTION_PERIOD).delete_all
    Session.where("updated_at < ?", RETENTION_PERIOD).delete_all
  end
end
