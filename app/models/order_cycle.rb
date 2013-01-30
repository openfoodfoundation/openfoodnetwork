class OrderCycle < ActiveRecord::Base
  belongs_to :coordinator, :class_name => 'Enterprise'
  belongs_to :coordinator_admin_fee, :class_name => 'EnterpriseFee'
  belongs_to :coordinator_sales_fee, :class_name => 'EnterpriseFee'

  has_many :exchanges, :dependent => :destroy

  attr_accessor :incoming_exchanges, :outgoing_exchanges

  validates_presence_of :name, :coordinator_id

  scope :active, lambda { where('orders_open_at <= ? AND orders_close_at >= ?', Time.now, Time.now) }
  scope :inactive, lambda { where('orders_open_at > ? OR orders_close_at < ?', Time.now, Time.now) }


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
