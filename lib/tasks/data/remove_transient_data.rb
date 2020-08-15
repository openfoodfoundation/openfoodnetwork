# frozen_string_literal: true

class RemoveTransientData
  # This model lets us operate on the sessions DB table using ActiveRecord's
  # methods within the scope of this service. This relies on the AR's
  # convention where a Session model maps to a sessions table.
  class Session < ActiveRecord::Base
  end

  def call
    Rails.logger.info("RemoveTransientData: processing")

    Spree::StateChange.delete_all("created_at < '#{1.month.ago.to_date}'")
    Spree::LogEntry.delete_all("created_at < '#{1.month.ago.to_date}'")
    Session.delete_all("created_at < '#{2.weeks.ago.to_date}'")
  end
end
