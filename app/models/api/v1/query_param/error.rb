class Api::V1::QueryParam::Error
  # When multiple errors are encountered, we chose the most generic
  # https://jsonapi.org/format/#errors-processing
  # List of available rails errors
  # https://gist.github.com/mlanett/a31c340b132ddefa9cca
  AVAILABLE_STATUSES_IN_ORDER_OF_PRIORITY = [
    :bad_request,           # when param cannot be parsed
    :unprocessable_entity,  # when param can be parsed but value invalid
  ]
  
  def self.get_top_status(statuses)
    statuses.sort_by(&AVAILABLE_STATUSES_IN_ORDER_OF_PRIORITY.method(:index))
  end

  attr_reader :status, :error

  def initialize(param_name, status, detail)
    @param_name=param_name
    @status = status
    @detail = @detail

    validate_status    
  end

  # Error formatting from this standard
  # https://jsonapi.org/format/#error-objects
  def get
    {
      status: @status,
      code: Rack::Utils::SYMBOL_TO_STATUS_CODE[@status],
      title: "Invalid query parameter",
      detail: @detail,
      source: {
        parameter: @param_name,
      },
    }
  end


  private

  def validate_status
    @status.in?(AVAILABLE_STATUSES_IN_ORDER_OF_PRIORITY)
  end
end
