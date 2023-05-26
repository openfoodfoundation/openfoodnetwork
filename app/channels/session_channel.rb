# frozen_string_literal: true

class SessionChannel < ApplicationCable::Channel
  def self.for_request(request)
    "SessionChannel:#{request.session.id}"
  end

  def subscribed
    return reject if current_user.nil?

    stream_from "SessionChannel:#{session_id}"
  end
end
