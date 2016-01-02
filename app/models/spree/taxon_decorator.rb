Spree::Taxon.class_eval do
  attachment_definitions[:icon][:path] = 'public/images/spree/taxons/:id/:style/:basename.:extension'
  attachment_definitions[:icon][:url] = '/images/spree/taxons/:id/:style/:basename.:extension'

  # Indicate which filters should be used for this taxon
  def applicable_filters
    fs = []
    # fs << Spree::ProductFilters.distributor_filter if Spree::ProductFilters.respond_to? :distributor_filter
    fs
  end

  # Find all the taxons of supplied products for each enterprise, indexed by enterprise.
  # Format: {enterprise_id => [taxon_id, ...]}
  def self.supplied_taxons
    taxons = {}

    Spree::Taxon
      .joins(products: :supplier)
      .select('spree_taxons.*, enterprises.id AS enterprise_id')
      .each do |t|
      taxons[t.enterprise_id.to_i] ||= Set.new
      taxons[t.enterprise_id.to_i] << t.id
    end

    taxons
  end

  # Find all the taxons of distributed products for each enterprise, indexed by enterprise.
  # Format: {enterprise_id => [taxon_id, ...]}
  def self.distributed_taxons
    taxons = {}

    Spree::Taxon
      .joins(:products)
      .merge(Spree::Product.with_order_cycles_outer)
      .where('o_exchanges.incoming = ?', false)
      .select('spree_taxons.*, o_exchanges.receiver_id AS enterprise_id')
      .each do |t|
      taxons[t.enterprise_id.to_i] ||= Set.new
      taxons[t.enterprise_id.to_i] << t.id
    end

    taxons
  end
end
