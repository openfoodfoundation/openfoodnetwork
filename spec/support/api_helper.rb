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
  end
end
