Spree::Product.class_eval do
  belongs_to :supplier
  has_and_belongs_to_many :distributors

  attr_accessible :supplier_id, :distributor_ids

  validates_presence_of :distributors

  scope :in_supplier, lambda { |supplier| where(:supplier_id => supplier) }
  scope :in_distributor, lambda { |distributor| joins(:distributors).where('distributors.id = ?', distributor) }
end
