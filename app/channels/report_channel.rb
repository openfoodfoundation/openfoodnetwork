class ReportChannel < ApplicationCable::Channel
  def subscribed
    stream_from "reports"
  end

  def receive
    ActionCable.server.broadcast("reports", "ActionCable is connected")
  end
end
