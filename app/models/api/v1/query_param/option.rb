# Query param type options handler
# See: Api::V1::QueryParam::Type for more info
#
class Api::V1::QueryParam::Option
  SUPPORTED_OPT_PROPS = [
    :type,     # opt type, class_name.underscore.to_sym, 
               # :boolean also accepted although not a real ruby class
    :default,  # opt default value
    :required, # ensure present
    :in,       # ensure opt value in array
  ]



  def initialize(params, param_name, type, opts, supported_options)
    @params = params
    @param_name = param_name
    @type = type
    @opts = opts
    @supported_options = supported_options

    parse
  end

  def get
    
  end


  private

  def parse
    validate
    @opts = defaults.merge(@opts)
    convert_values
  end
  
  def validate
    @opts.each do |opt_key, opt_val|
      validate_opt_supported(opt_key)
      validate_opt_value_type(opt_key, opt_val)
    end
  end

  def validate_opt_supported(opt_key)
    unless @supported_options&.key?(opt_key)
      raise_opt_error(opt_key, "not supported" )
    end
  end

  def validate_opt_value_type(opt_key, opt_val)
    return unless type = @supported_options.dig(opt_key, :type)
    
    if type == :boolean
      opt_val.in?([true, false])
    end
    unless type.in?(TYPE_CHECKS.keys)
      raise_opt_error(opt_key, "invalid type specified: #{type}")
    end
    
    unless TYPE_CHECKS[type](opt_val)
      raise_opt_error(opt_key, "value not of type: #{type}")
    end
  end

  def defaults
    @supported_options.map{|opt_key, opt_val| {"#{opt_key}": opt_val[:default]}.compact}
  end
 
  def raise_opt_error(opt_key, msg)
    raise_error(ArgumentError, "#{@param_name}: #{@type}: #{opt_key}: #{msg}")
  end
end
