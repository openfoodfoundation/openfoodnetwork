# A class to standardize controller query param handeling for the api
#
#
# Example:
#
# # Given incoming request controller params:
#
# params = {
#   some_boolean: "true",
#   some_datetime_arr, "2023-01-02T00:00:00,2023-01-02T00:00:00",
#   ...
# }
#
# # We could declare:
#
# query_params = Api::V1::QueryParam.new(params, {
#   some_boolean: :boolean,  # shorthand when using default opts
#   "some_datetime_arr[]": { type: :array, items: { type: datetime } }
# })
#
# # If params invalid: render #json_response with correct message and status code
# query_params.valid? || render query_params.json_response
#
# # #get returns params parsed to appropriate rails data type
# parsed_params = query_params.get  # get all
# some_boolean = query_params.get(:some_boolean)  # get single
# ------------------------------------
#
# QueryParam type classes
#
# Only available type classes should be defined inside the query_params/types directory. Eg:
# Api::V1::QueryParam::Types::DateTime < Api::V1::QueryParam::Type
# They are then automatically made available through their location and namespace.
#
class Api::V1::QueryParam
  def initialize(params, declaration)
    @params = params
    @declaration = declaration
    @types = get_types
    @opts = get_opts
    @type_objs = get_type_objs
    @parsed_params = {}
    @errors = []
    @status = :ok

    combine_data
  end

  def json_response
    { json: { errors: @errors }, status: @status }
  end

  def valid?
    @errors.any?
  end

  def get(param = nil)
    param ? @parsed_params[param] : @parsed_params
  end


  private

  def get_types
    @declaration.map do |param_name, opts|
      type = opts.is_a?(Hash) ? opts[:type] : opts
      raise_error(ArgumentError, "#{param_name}: type missing") if type.blank?

      {"#{param_name}": type}
    end
  end

  def get_opts
    @declaration.map do |param_name, opts| 
      { "#{param_name}": opts.is_a?(Hash) ? opts.except(:type) : {} }
    end
  end

  def get_type_objs
    @types.map do |param_name, type|
      Api::V1::QueryParam::Type.get_object(type, @params, param_name, @opts)
    end
  end

  def combine_data
    combine_errors
    combine_status
  end

  def combine_errors
    @errors = @type_objs.map{|o| o.error}.compact
  end

  def combine_statuses
    error_statuses = @type_objs.map{|o| o.status}.except{|s| s == :ok}

    if error_statuses.any?
      @status = Api::V1::QueryParam::Error.get_top_status(error_statuses)
    end
  end
end
