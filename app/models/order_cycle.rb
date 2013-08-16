class OrderCycle < ActiveRecord::Base
  belongs_to :coordinator, :class_name => 'Enterprise'
  has_and_belongs_to_many :coordinator_fees, :class_name => 'EnterpriseFee', :join_table => 'coordinator_fees'

  has_many :exchanges, :dependent => :destroy

  # TODO: DRY the incoming/outgoing clause used in several cases below
  # See Spree::Product definition, scopes variants and variants_including_master
  # This will require these accessors to be renamed
  attr_accessor :incoming_exchanges, :outgoing_exchanges

  validates_presence_of :name, :coordinator_id

  scope :active, lambda { where('orders_open_at <= ? AND orders_close_at >= ?', Time.now, Time.now) }
  scope :active_or_complete, lambda { where('orders_open_at <= ?', Time.now) }
  scope :inactive, lambda { where('orders_open_at > ? OR orders_close_at < ?', Time.now, Time.now) }

  scope :distributing_product, lambda { |product| joins(:exchanges => :variants).
    where('exchanges.sender_id = order_cycles.coordinator_id').
    where('spree_variants.id IN (?)', product.variants_including_master.map(&:id)).
    select('DISTINCT order_cycles.*') }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('coordinator_id IN (?)', user.enterprises.map {|enterprise| enterprise.id })
    end
  }

  def suppliers
    self.exchanges.where(:receiver_id => self.coordinator).map(&:sender).uniq
  end

  def distributors
    self.exchanges.where(:sender_id => self.coordinator).map(&:receiver).uniq
  end

  def variants
    self.exchanges.map(&:variants).flatten.uniq
  end

  def distributed_variants
    self.exchanges.where(:sender_id => self.coordinator).map(&:variants).flatten.uniq
  end

  def distributed_variants_by(distributor)
    self.exchanges.where(:sender_id => self.coordinator, :receiver_id => distributor).
      map(&:variants).flatten.uniq
  end

  def products
    self.variants.map(&:product).uniq
  end

  def has_distributor?(distributor)
    self.distributors.include? distributor
  end


end
