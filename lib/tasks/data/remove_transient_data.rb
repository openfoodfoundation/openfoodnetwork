# frozen_string_literal: true

class RemoveTransientData
  # This model lets us operate on the sessions DB table using ActiveRecord's
  # methods within the scope of this service. This relies on the AR's
  # convention where a Session model maps to a sessions table.
  class Session < ActiveRecord::Base
  end

  def call
    Rails.logger.info("#{self.class.name}: processing")

    Spree::StateChange.where("created_at < ?", retention_period).delete_all
    Spree::LogEntry.where("created_at < ?", retention_period).delete_all
    Session.where("updated_at < ?", retention_period).delete_all
  end

  private

  def retention_period
    2.months.ago.to_date
  end
end
