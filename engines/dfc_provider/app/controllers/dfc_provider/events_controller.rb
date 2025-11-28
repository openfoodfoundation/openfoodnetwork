# frozen_string_literal: true

# Webhook events
module DfcProvider
  class EventsController < DfcProvider::ApplicationController
    rescue_from JSON::ParserError, with: -> do
      head :bad_request
    end

    # Trigger a webhook event.
    #
    # The only supported event is a `refresh` event of permissions.
    # It means that our permissions to access data on another platform changed.
    # We will need to pull the updated data.
    def create
      event = JSON.parse(request.body.read)
      enterprises_url = event["enterpriseUrlid"]

      if enterprises_url.blank?
        render status: :bad_request, json: {
          success: false,
          message: "Missing parameter `enterpriseUrlid`",
        }
        return
      end
      render json: { success: true }
    end
  end
end
