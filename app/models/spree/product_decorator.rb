Spree::Product.class_eval do
  belongs_to :supplier, :class_name => 'Enterprise'

  has_many :product_distributions, :dependent => :destroy
  has_many :distributors, :through => :product_distributions

  accepts_nested_attributes_for :product_distributions, :allow_destroy => true

  attr_accessible :supplier_id, :distributor_ids, :product_distributions_attributes, :group_buy, :group_buy_unit_size

  validates_presence_of :supplier

  scope :in_supplier, lambda { |supplier| where(:supplier_id => supplier) }
  scope :in_distributor, lambda { |distributor| joins(:product_distributions).where('product_distributions.distributor_id = ?', (distributor.respond_to?(:id) ? distributor.id : distributor.to_i)) }


  def shipping_method_for_distributor(distributor)
    distribution = self.product_distributions.find_by_distributor_id(distributor)
    raise ArgumentError, "This product is not available through that distributor" unless distribution
    distribution.shipping_method
  end


  # Build a product distribution for each distributor
  def build_product_distributions
    Distributor.all.each do |distributor|
      unless self.product_distributions.find_by_distributor_id distributor.id
        self.product_distributions.build(:distributor => distributor)
      end
    end
  end
end
