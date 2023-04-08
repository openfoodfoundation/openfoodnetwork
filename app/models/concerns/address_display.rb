# frozen_string_literal: true

module AddressDisplay
  def full_name_reverse
    [lastname, firstname].reject(&:blank?).join(" ")
  end

  def full_name_for_sorting
    [last_name, first_name].reject(&:blank?).join(", ")
  end
end
