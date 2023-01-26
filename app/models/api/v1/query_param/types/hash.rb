# See: Api::V1::QueryParam where this class is used internally
# See: Api::V1::QueryParam::Type for relevant variables and methods
#
class Api::V1::QueryParam::Types::Hash < Api::V1::QueryParam::Type 
  SUPPORTED_OPTS = {
    # size is only checked if value received
    min_size: { type: :integer, default: 1 },
    max_size: { type: :integer, default: 365 }, # See array for discussion on size
  }
  
  # set @parsed_param given incoming @param and @opts, #set_error(status, msg) if @param invalid
  def parse

  end
end
