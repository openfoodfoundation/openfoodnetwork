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
      unless current_user.is_a? ApiUser
        unauthorized "You need to authenticate as authorised platform (client_id)."
        return
      end
      unless current_user.id == "lf-dev"
        unauthorized "Your client_id is not authorised on this platform."
        return
      end

      event = JSON.parse(request.body.read)
      enterprises_url = event["enterpriseUrlid"]

      if enterprises_url.blank?
        render status: :bad_request, json: {
          success: false,
          message: "Missing parameter `enterpriseUrlid`",
        }
        return
      end

      importer = DfcImporter.new
      importer.import_enterprise_profiles(current_user.id, enterprises_url)

      if importer.errors.blank?
        render json: { success: true }
      else
        render json: { success: true, messages: error_messages(importer.errors) }
      end
    end

    private

    def unauthorized(message)
      render_message(:unauthorized, message)
    end

    def render_message(status, message)
      render status:, json: { success: false, message: }
    end

    def error_messages(errors)
      errors.map do |error|
        id = error.record.try(:semantic_link)&.semantic_id
        "#{id}: #{error.message}"
      end
    end
  end
end
