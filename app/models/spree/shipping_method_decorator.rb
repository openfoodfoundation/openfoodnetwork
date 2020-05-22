Spree::ShippingMethod.class_eval do
  acts_as_taggable

  has_many :distributor_shipping_methods
  has_many :distributors, through: :distributor_shipping_methods, class_name: 'Enterprise', foreign_key: 'distributor_id'

  after_save :touch_distributors

  validate :distributor_validation

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      joins(:distributors).
        where('distributors_shipping_methods.distributor_id IN (?)', user.enterprises.select(&:id)).
        select('DISTINCT spree_shipping_methods.*')
    end
  }

  scope :for_distributors, ->(distributors) {
    non_unique_matches = unscoped.joins(:distributors).where(enterprises: { id: distributors })
    where(id: non_unique_matches.map(&:id))
  }
  scope :for_distributor, lambda { |distributor|
    joins(:distributors).
      where('enterprises.id = ?', distributor)
  }

  scope :by_name, -> { order('spree_shipping_methods.name ASC') }
  scope :display_on_checkout, -> { where("spree_shipping_methods.display_on is null OR spree_shipping_methods.display_on = ''") }

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
        map { |sm| [sm.distributor_id.to_i, { pickup: sm.pickup, delivery: sm.delivery }] }
    ]
  end

  # This method is overriden so that we can remove the restriction added in Spree
  #   Spree restricts shipping method calculators to the ones that inherit from Spree::Shipping::ShippingCalculator
  #   Spree::Shipping::ShippingCalculator makes sure that calculators are able to handle packages and not orders as input
  #   This is not necessary in OFN because calculators in OFN are already customized to work with different types of input
  def self.calculators
    spree_calculators.send model_name_without_spree_namespace
  end

  # This is bypassing the validation of shipping method zones on checkout
  # It allows checkout using shipping methods without zones (see issue #3928 for details)
  #   and it allows checkout with addresses outside of the zones of the selected shipping method
  def include?(address)
    address.present?
  end

  def has_distributor?(distributor)
    distributors.include?(distributor)
  end

  def adjustment_label
    I18n.t('shipping')
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
    distributors.each do |distributor|
      distributor.touch if distributor.persisted?
    end
  end

  def distributor_validation
    validates_with DistributorsValidator
  end
end
