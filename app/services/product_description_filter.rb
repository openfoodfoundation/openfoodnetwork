# frozen_string_literal: true

class ProductDescriptionFilter
  FILTERED_CHARACTERS = {
    "&amp;amp;" => "&",
    "&amp;" => "&",
    "&nbsp;" => " "
  }.freeze

  def self.filter(descripton)
    FILTERED_CHARACTERS.each do |character, sub|
      descripton = descripton.gsub(character, sub)
    end
    descripton
  end
end
