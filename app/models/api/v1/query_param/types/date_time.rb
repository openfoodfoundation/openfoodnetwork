class Api::V1::QueryParam::Types::DateTime < Api::V1::QueryParam::Type
  SUPPORTED_OPTS = {
    no_future: { type: :boolean, default: false } # If accept future datetimes
  }
  
  # set @parsed_param given incoming @param and @opts, #set_error(status, msg) if @param invalid
  def parse
    convert_param
    valid? && handle_options
  end

  private 

  def convert_param
    begin
      @parsed_param = @param.to_datetime
    rescue
      set_error(:unprocessable_entity, "Expected datetime. Recommended format: ISO 8601")
    end
  end

  def handle_options
    if @opts[:no_future] && @parsed_param.future?
      set_error(:unprocessable_entity, "Future datetime not accepted")
    end
  end
end
