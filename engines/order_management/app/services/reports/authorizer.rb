module Reports
  class Authorizer
    class ParameterNotAllowedError < StandardError; end

    attr_accessor :parameters, :permissions

    def initialize(parameters, permissions)
      @parameters = parameters
      @permissions = permissions
    end
  end
end
