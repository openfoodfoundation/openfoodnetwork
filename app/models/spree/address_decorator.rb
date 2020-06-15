Spree::Address.class_eval do
  include AddressDisplay

  has_one :enterprise, dependent: :restrict_with_exception
  belongs_to :country, class_name: "Spree::Country"

  after_save :touch_enterprise

  geocoded_by :geocode_address

  delegate :name, to: :state, prefix: true, allow_nil: true

  def geocode_address
    render_address([address1, address2, zipcode, city, country.andand.name, state.andand.name])
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
