# See: Api::V1::QueryParam where this class is used internally
# See: Api::V1::QueryParam::Type for relevant variables and methods
#
class Api::V1::QueryParam::Types::Array < Api::V1::QueryParam::Type 
  SUPPORTED_OPTS = {
    items:  { type: :hash }, # options for contained items
    # Length is only checked if value received
    min_items: { type: :integer, default: 1 },
    # Support max eg: 1 full year of dates. Although there isn't technically a limit to the length of query strings
    # Modern browsers support ca 60k chars.
    # https://stackoverflow.com/questions/812925/what-is-the-maximum-possible-length-of-a-query-string
    # 365 datetimes "&obj[prop][sub_prop][]=2023-01-01T00:00:00" produce ca 62050 chars
    # For larger amounts of data it might be wise to use something other than query params
    max_items: { type: :integer, default: 365 }, 
    unique_items: { type: :boolean, default: false },
  }
  
  # set @parsed_param given incoming @param and @opts, #set_error(status, msg) if @param invalid
  def parse
    validate_options
    @item_type = @opts.dig(:items, :type)
    convert_param
    valid? && handle_options     
  end
  
  def convert_param
    # If request contains param= instead of param[]=, we allow it as a shorthand for single item
    @param = [@param] if @param.is_a?(String)
    
    unless @param.is_a?(Array)
      if item_type.present?
        set_error(:unprocessable_entity, "Expected array of #{item_type}")
      else
        set_error(:unprocessable_entity, "Expected array")
      end
    end

    validate_length
    convert_items
  end

  def validate_length
    if @param.length > @opts[:max_items]
      set_error(:unprocessable_entity, "Array max length #{@opts[:max_items]}")
    elsif @param.length < @opts[:min_items]
      set_error(:unprocessable_entity, "Array min length #{@opts[:min_items]}")
    end
  end

  def convert_items
    @param.each do |item|
      Api::V1::QueryParam::Type.get_object(item, @params, @name, @opts)
    end
  end
end
