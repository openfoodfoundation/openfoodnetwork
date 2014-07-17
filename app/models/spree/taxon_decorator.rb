Spree::Taxon.class_eval do
  self.attachment_definitions[:icon][:path] = 'app/public/spree/taxons/:id/:style/:basename.:extension'


  # Indicate which filters should be used for this taxon
  def applicable_filters
    fs = []
    #fs << Spree::ProductFilters.distributor_filter if Spree::ProductFilters.respond_to? :distributor_filter
    fs
  end
end
