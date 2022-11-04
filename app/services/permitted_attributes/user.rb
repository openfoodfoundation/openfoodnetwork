# frozen_string_literal: true

module PermittedAttributes
  class User
    def initialize(params, resource_name = :user)
      @params = params
      @resource_name = resource_name
    end

    def call(extra_permitted_attributes = [])
      @params.require(@resource_name).
        permit(permitted_attributes + extra_permitted_attributes)
    end

    private

    def permitted_attributes
      [
        :email, :password, :password_confirmation, :disabled,
        { webhook_endpoints_attributes: [:id, :url] },
      ]
    end
  end
end
