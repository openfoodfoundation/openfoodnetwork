Spree::ShippingMethod.class_eval do
  has_many :distributor_shipping_methods
  has_many :distributors, through: :distributor_shipping_methods, class_name: 'Enterprise', foreign_key: 'distributor_id'

  after_save :touch_distributors
  attr_accessible :distributor_ids, :description
  attr_accessible :require_ship_address

  validates :distributors, presence: { message: "^At least one hub must be selected" }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      joins(:distributors).
      where('distributors_shipping_methods.distributor_id IN (?)', user.enterprises).
      select('DISTINCT spree_shipping_methods.*')
    end
  }

  scope :for_distributor, lambda { |distributor|
    joins(:distributors).
    where('enterprises.id = ?', distributor)
  }

  scope :by_name, order('spree_shipping_methods.name ASC')

  def available_to_order_with_distributor_check?(order, display_on=nil)
    available_to_order_without_distributor_check?(order, display_on) &&
      self.distributors.include?(order.distributor)
  end
  alias_method_chain :available_to_order?, :distributor_check

  def within_zone?(order)
    if order.ship_address
      zone && zone.include?(order.ship_address)
    else
      true # Shipping methods are available before we've selected an address
    end
  end

  def has_distributor?(distributor)
    self.distributors.include?(distributor)
  end

  def adjustment_label
    'Shipping'
  end

  private

  def touch_distributors
    distributors.each(&:touch)
  end
end
