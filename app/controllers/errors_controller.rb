# frozen_string_literal: true

class ErrorsController < ApplicationController
  layout "errors"

  def not_found
    Bugsnag.notify("404") do |event|
      event.severity = "info"

      event.add_metadata(:request, :env, request.env)
    end
    render status: :not_found, formats: :html
  end

  def internal_server_error
    render status: :internal_server_error
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end
end
