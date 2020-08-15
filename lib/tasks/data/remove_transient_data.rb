# frozen_string_literal: true

class RemoveTransientData
  # This model lets us operate on the sessions DB table using ActiveRecord's
  # methods within the scope of this service. This relies on the AR's
  # convention where a Session model maps to a sessions table.
  class Session < ActiveRecord::Base
  end

  def call
    Rails.logger.info("RemoveTransientData: processing")

    Spree::StateChange.delete_all("created_at < '#{retention_period}'")
    Spree::LogEntry.delete_all("created_at < '#{retention_period}'")
    Session.delete_all("updated_at < '#{retention_period}'")
  end

  private

  def retention_period
    2.months.ago.to_date
  end
end
