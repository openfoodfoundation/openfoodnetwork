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


  # -- Fees
  def ensure_correct_adjustments_for(line_item)
    EnterpriseFee.clear_all_adjustments_for line_item
    create_adjustments_for line_item
  end


  private

  # -- Fees
  def create_adjustments_for(line_item)
    fees_for(line_item).each { |fee| create_adjustment_for_fee line_item, fee[:enterprise_fee], fee[:label], fee[:role] }
  end

  def fees_for(line_item)
    fees = []

    # If there are multiple distributors with this variant, won't this mean that we get a fee charged for each of them?
    # We just want the one matching line_item.order.distributor

    exchanges_carrying(line_item).each do |exchange|
      exchange.enterprise_fees.each do |enterprise_fee|
        role = exchange.incoming? ? 'supplier' : 'distributor'
        fees << {enterprise_fee: enterprise_fee,
                 label: adjustment_label_for(line_item, enterprise_fee, role),
                 role: role}
      end
    end

    coordinator_fees.each do |enterprise_fee|
      fees << {enterprise_fee: enterprise_fee,
               label: adjustment_label_for(line_item, enterprise_fee, 'coordinator'),
               role: 'coordinator'}
    end

    fees
  end

  def create_adjustment_for_fee(line_item, enterprise_fee, label, role)
    a = enterprise_fee.create_adjustment(label, line_item.order, line_item, true)
    AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role
  end

  def adjustment_label_for(line_item, enterprise_fee, role)
    "#{line_item.variant.product.name} - #{enterprise_fee.fee_type} fee by #{role} #{enterprise_fee.enterprise.name}"
  end

  def exchanges_carrying(line_item)
    coordinator = line_item.order.order_cycle.coordinator
    distributor = line_item.order.distributor

    exchanges.to_enterprises([coordinator, distributor]).with_variant(line_item.variant)
  end
end
