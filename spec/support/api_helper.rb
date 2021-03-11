# frozen_string_literal: true

module OpenFoodNetwork
  module ApiHelper
    def json_response
      json_response = JSON.parse(response.body)
      case json_response
      when Hash
        json_response.with_indifferent_access
      when Array
        json_response.map(&:with_indifferent_access)
      else
        json_response
      end
    end

    def assert_unauthorized!
      expect(json_response).to eq("error" => "You are not authorized to perform that action.")
      expect(response.status).to eq 401
    end

    def image(filename)
      File.open(Rails.root + "spec/support/fixtures" + filename)
    end
  end
end
