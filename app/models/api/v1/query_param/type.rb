# Info for QueryParam::Type classes inheriting from this Base:
#
# See Api::V1::QueryParam::Types::DateTime for examples
#
# - #parse: is your main function to derive @parsed_param given incoming @param and @opts
# - @param: query param value
# - @parsed_param: variable where to store the result after parsing param to rails friendly format
# - @opts: incoming options hash.
#
# - TYPE_SPECIFIC_OPTIONS: Use this constant to define supported options for your type. 
#   see Api::V1::QueryParam::Option
#
# - #set_error(status, msg): Set your error status and message if @param invalid 
#   see Api::V1::QueryParam::Error
#
class Api::V1::QueryParam::Type
  TYPES_PARENT_MODULE = Api::V1::QueryParam::Types.freeze

  class << self
    def get_object(type, params, param_name, opts)
      "#{TYPES_PARENT_MODULE.to_s}::#{type.classify}".constantize.new(params, param_name, opts)
    end
  end
  
  attr_reader :error, :status

  def initialize(
    params,
    param_name, 
    opts,
    param_value = nil,
  )
    @params = params
    @param_name = param_name
    @param = param_value || param_value(param_name)
    @type = self.class.param_name.underscore.to_sym
    @error = {}
    @status = :ok
    @parsed_param = nil
    @opts = Api::V1::QueryParam::Option.new(@params, @param_name, @type, @opts, SUPPORTED_OPTS).get
    
    preprocess
    valid? && parse
  end

  def valid?
    @errors.none?
  end

  def get
    @parsed_param
  end


  private

  def set_error(status, detail)
    @status = status
    @error = Api::V1::QueryParam::Error.new(@param_name, status, title).get
  end

  def preprocess
    if @param.blank?
      preprocess_blank
    elsif @param.is_a?(Hash)
      preprocess_hash
    end
  end

  def preprocess_blank
    # This might be a bit strict but imagine it could help debugging and prevent unexpected responses
    set_error(:bad_request, "Blank value received") if param_received?
  end



  # Only way to get a hash is with query params as nested members under a specified param family:
  #
  # 1. We define a param param_name eg param[family]
  # 2. The request sends params with deeper nesting eg:
  #
  #    incoming_param="param[family][family2]=value"
  #    params = Rack::Utils.parse_nested_query(incoming_param)
  #       # {"param"=>{"family"=>{"family2"=>"value"}}}
  #    specified_param = params["param"]["family"]  
  #       # { "family2": "value"}
  #    specified_param.is_a?(Hash)
  #       # true
  # 
  def preprocess_hash
    unless @type == :hash
      set_error(:unprocessable_entity, "Query parameter family nested deeper than specification")
    end
  end

  # Param can be received with null value
  def param_received?
    obj = @params

    param_keys(@param_name).each do |key|
      obj.key?(key) && obj = obj[key] || return false
    end

    true
  end

  def param_value(param_name)
    @params.dig(*param_keys(param_name))
  end

  def param_keys(param_name)
    Rack::Utils.parse_nested_query(@param_name)
  end
end
