# Refers to an administrative division, unit, entity, area or region
# of a country.
Spree::State.class_eval do

  # Method for displaying the state in the UI
  #
  # @return [String]
  def display_name
    name_or_abbreviation
  end

  private

  # Depending on the configured `state_text_attribute`
  # of this instance of ofn, will either return the
  # name or the abbreviation of the state.
  #
  # @return [String]
  def name_or_abbreviation
    case Rails.configuration.state_text_attribute
    when 'abbr'
      abbr
    else
      name
    end
  end
end
