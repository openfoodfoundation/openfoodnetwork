Spree::Product.class_eval do
  belongs_to :supplier

  has_many :product_distributions, :dependent => :destroy
  has_many :distributors, :through => :product_distributions

  accepts_nested_attributes_for :product_distributions, :allow_destroy => true

  attr_accessible :supplier_id, :distributor_ids

  validates_presence_of :supplier

  scope :in_supplier, lambda { |supplier| where(:supplier_id => supplier) }
  scope :in_distributor, lambda { |distributor| joins(:product_distributions).where('product_distributions.distributor_id = ?', (distributor.respond_to?(:id) ? distributor.id : distributor.to_i)) }
end
