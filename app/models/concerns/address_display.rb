module AddressDisplay
  def full_name_reverse
    [lastname, firstname].reject(&:blank?).join(" ")
  end
end
