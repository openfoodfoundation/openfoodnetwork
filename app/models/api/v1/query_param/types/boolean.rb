class Api::V1::QueryParam::Types::Boolean < Api::V1::QueryParam::Type 
  # set @parsed_param given incoming @param and @opts, #set_error(status, msg) if @param invalid
  def parse
    convert_param
  end

  private

  def convert_param
    if @param == "true"
      @parsed_param = true 
    elsif @param == "false"
      @parsed_param = false 
    else
      set_error(:bad_request, "Expected value true or false")
    end
  end
end
