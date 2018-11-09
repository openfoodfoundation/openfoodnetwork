Spree::Address.class_eval do
  has_one :enterprise, dependent: :restrict
  belongs_to :country, class_name: "Spree::Country"

  after_save :touch_enterprise

  geocoded_by :geocode_address

  delegate :name, to: :state, prefix: true, allow_nil: true

  # Google recommends to use the formatting convention of the country.
  # This format is fairly general and hopefully applies to most countries.
  # Otherwise we need a library to format it depending on the country.
  def geocode_address
    render_address([address1, address2, zipcode, city, state.andand.name, country.andand.name])
  end

  def full_address
    render_address([address1, address2, city, zipcode, state.andand.name])
  end

  def address_part1
    render_address([address1, address2])
  end

  def address_part2
    render_address([city, zipcode, state.andand.name])
  end

  private

  def touch_enterprise
    enterprise.andand.touch
  end

  def render_address(parts)
    parts.select(&:present?).join(', ')
  end
end
