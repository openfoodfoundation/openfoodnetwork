Spree::Product.class_eval do
  belongs_to :supplier
  has_and_belongs_to_many :distributors

  attr_accessible :supplier_id, :distributor_ids

  validates_presence_of :distributors
end
