module RegistrationHelper
  # Generates the Angular query for the State select
  #
  # @return [String]
  def state_options_query
    attribute = Rails.configuration.state_text_attribute

    "s.id as s.#{attribute} for s in enterprise.country.states"
  end
end
