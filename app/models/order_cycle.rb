class OrderCycle < ActiveRecord::Base
  belongs_to :coordinator, :class_name => 'Enterprise'
  belongs_to :coordinator_admin_fee, :class_name => 'EnterpriseFee'
  belongs_to :coordinator_sales_fee, :class_name => 'EnterpriseFee'

  has_many :exchanges, :dependent => :destroy

  validates_presence_of :name


  def suppliers
    self.exchanges.where(:receiver_id => self.coordinator).map(&:sender).uniq
  end

  def distributors
    self.exchanges.where(:sender_id => self.coordinator).map(&:receiver).uniq
  end

  def variants
    self.exchanges.map(&:variants).flatten.uniq
  end

  def products
    self.variants.map(&:product).uniq
  end

end
