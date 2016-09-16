Spree::Taxon.class_eval do
  has_many :classifications, :dependent => :destroy


  self.attachment_definitions[:icon][:path] = 'public/images/spree/taxons/:id/:style/:basename.:extension'
  self.attachment_definitions[:icon][:url] = '/images/spree/taxons/:id/:style/:basename.:extension'

  after_save :refresh_products_cache


  # Indicate which filters should be used for this taxon
  def applicable_filters
    fs = []
    #fs << Spree::ProductFilters.distributor_filter if Spree::ProductFilters.respond_to? :distributor_filter
    fs
  end

  # Find all the taxons of supplied products for each enterprise, indexed by enterprise.
  # Format: {enterprise_id => [taxon_id, ...]}
  def self.supplied_taxons
    taxons = {}

    Spree::Taxon.
      joins(:products => :supplier).
      select('spree_taxons.*, enterprises.id AS enterprise_id').
      each do |t|
        taxons[t.enterprise_id.to_i] ||= Set.new
        taxons[t.enterprise_id.to_i] << t.id
      end

    taxons
  end

  # Find all the taxons of distributed products for each enterprise, indexed by enterprise.
  # May return :all taxons (distributed in open and closed order cycles),
  # or :current taxons (distributed in an open order cycle).
  #
  # Format: {enterprise_id => [taxon_id, ...]}
  def self.distributed_taxons(which_taxons=:all)
    # TODO: Why can't we merge(Spree::Product.with_order_cycles_inner) here?
    taxons = Spree::Taxon.
      joins(products: {variants_including_master: {exchanges: :order_cycle}}).
      merge(Exchange.outgoing).
      select('spree_taxons.*, exchanges.receiver_id AS enterprise_id')

    taxons = taxons.merge(OrderCycle.active) if which_taxons == :current

    taxons.inject({}) do |ts, t|
      ts[t.enterprise_id.to_i] ||= Set.new
      ts[t.enterprise_id.to_i] << t.id
      ts
    end
  end


  private

  def refresh_products_cache
    products(:reload).each &:refresh_products_cache
  end
end
