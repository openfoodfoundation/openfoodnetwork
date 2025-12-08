# frozen_string_literal: true

module OpenFoodNetwork
  module ApiHelper
    def json_response
      response.parsed_body
    end

    def assert_unauthorized!
      expect(json_response).to eq("error" => "You are not authorized to perform that action.")
      expect(response).to have_http_status :unauthorized
    end
  end
end
