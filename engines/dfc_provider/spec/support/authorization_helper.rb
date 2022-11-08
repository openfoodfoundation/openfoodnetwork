# frozen_string_literal: true

module AuthorizationHelper
  def authorise(email)
    token = JWT.encode({ email: email }, nil)
    request.headers["Authorization"] = "JWT #{token}"
  end
end
