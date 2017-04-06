Spree::ShippingMethod.class_eval do
  acts_as_taggable

  has_many :distributor_shipping_methods
  has_many :distributors, through: :distributor_shipping_methods, class_name: 'Enterprise', foreign_key: 'distributor_id'

  after_save :touch_distributors
  attr_accessible :distributor_ids, :description
  attr_accessible :require_ship_address, :tag_list

  validates_with DistributorsValidator

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


  # Return the services (pickup, delivery) that different distributors provide, in the format:
  # {distributor_id => {pickup: true, delivery: false}, ...}
  def self.services
    Hash[
      Spree::ShippingMethod.
        joins(:distributor_shipping_methods).
        group('distributor_id').
        select("distributor_id").
        select("BOOL_OR(spree_shipping_methods.require_ship_address = 'f') AS pickup").
        select("BOOL_OR(spree_shipping_methods.require_ship_address = 't') AS delivery").
        map { |sm| [sm.distributor_id.to_i, {pickup: sm.pickup == 't', delivery: sm.delivery == 't'}] }
    ]
  end

  def available_to_order_with_distributor_check?(order)
    available_to_order_without_distributor_check?(order) &&
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

  # Checks whether the shipping method is of delivery type, meaning that it
  # requires the user to specify a ship address at checkout. Note this is
  # a setting we added onto the +spree_shipping_methods+ table.
  #
  # @return [Boolean]
  def delivery?
    require_ship_address
  end

  private

  def touch_distributors
    distributors.each(&:touch)
  end
end
