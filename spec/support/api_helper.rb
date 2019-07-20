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

    def current_api_user
      @current_api_user ||= Spree::LegacyUser.new(email: "spree@example.com", enterprises: [])
    end

    def assert_unauthorized!
      json_response.should == { "error" => "You are not authorized to perform that action." }
      response.status.should == 401
    end

    def image(filename)
      File.open(Rails.root + "spec/support/fixtures" + filename)
    end
  end
end
