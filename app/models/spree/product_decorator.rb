Spree::Product.class_eval do
  belongs_to :supplier, :class_name => 'Enterprise'

  has_many :product_distributions, :dependent => :destroy
  has_many :distributors, :through => :product_distributions

  accepts_nested_attributes_for :product_distributions, :allow_destroy => true

  attr_accessible :supplier_id, :distributor_ids, :product_distributions_attributes, :group_buy, :group_buy_unit_size

  validates_presence_of :supplier


  # -- Joins
  scope :with_product_distributions_outer, joins('LEFT OUTER JOIN product_distributions ON product_distributions.product_id = spree_products.id')

  scope :with_order_cycles_outer, joins('LEFT OUTER JOIN spree_variants ON (spree_variants.product_id = spree_products.id)').
                                  joins('LEFT OUTER JOIN exchange_variants ON (exchange_variants.variant_id = spree_variants.id)').
                                  joins('LEFT OUTER JOIN exchanges ON (exchanges.id = exchange_variants.exchange_id)').
                                  joins('LEFT OUTER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)')

  scope :with_order_cycles_inner, joins('INNER JOIN spree_variants ON (spree_variants.product_id = spree_products.id)').
                                  joins('INNER JOIN exchange_variants ON (exchange_variants.variant_id = spree_variants.id)').
                                  joins('INNER JOIN exchanges ON (exchanges.id = exchange_variants.exchange_id)').
                                  joins('INNER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle_id)')

  # -- Scopes
  scope :in_supplier, lambda { |supplier| where(:supplier_id => supplier) }

  # Find products that are distributed via the given distributor EITHER through a product distribution OR through an order cycle
  scope :in_distributor, lambda { |distributor|
    distributor = distributor.respond_to?(:id) ? distributor.id : distributor.to_i

    with_product_distributions_outer.with_order_cycles_outer.
    where('product_distributions.distributor_id = ? OR (exchanges.sender_id = order_cycles.coordinator_id AND exchanges.receiver_id = ?)', distributor, distributor).
    select('distinct spree_products.*')
  }

  # Find products that are supplied by a given enterprise or distributed via that enterprise EITHER through a product distribution OR through an order cycle
  scope :in_supplier_or_distributor, lambda { |enterprise|
    enterprise = enterprise.respond_to?(:id) ? enterprise.id : enterprise.to_i

    with_product_distributions_outer.with_order_cycles_outer.
    where('spree_products.supplier_id = ? OR product_distributions.distributor_id = ? OR (exchanges.sender_id = order_cycles.coordinator_id AND exchanges.receiver_id = ?)', enterprise, enterprise, enterprise).
    select('distinct spree_products.*')
  }

  # Find products that are distributed by the given order cycle
  scope :in_order_cycle, lambda { |order_cycle| with_order_cycles_inner.
                                                where('exchanges.sender_id = order_cycles.coordinator_id').
                                                where('order_cycles.id = ?', order_cycle) }


  # -- Methods

  def shipping_method_for_distributor(distributor)
    distribution = self.product_distributions.find_by_distributor_id(distributor)
    raise ArgumentError, "This product is not available through that distributor" unless distribution
    distribution.shipping_method
  end


  # Build a product distribution for each distributor
  def build_product_distributions
    Enterprise.is_distributor.each do |distributor|
      unless self.product_distributions.find_by_distributor_id distributor.id
        self.product_distributions.build(:distributor => distributor)
      end
    end
  end
end
