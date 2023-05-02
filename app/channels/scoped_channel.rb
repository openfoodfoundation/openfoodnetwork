# frozen_string_literal: true

class ScopedChannel < ApplicationCable::Channel
  class << self
    def for_id(id)
      "ScopedChannel:#{id}"
    end
  end

  def subscribed
    stream_from "ScopedChannel:#{params[:id]}"
  end
end
