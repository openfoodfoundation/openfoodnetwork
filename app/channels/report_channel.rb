class ReportChannel < ApplicationCable::Channel
  def subscribed
    stream_from "reports"
  end
end
