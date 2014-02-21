Spree::Address.class_eval do
  has_one :enterprise
  belongs_to :country, class_name: "Spree::Country"

  geocoded_by :full_address

  delegate :name, :to => :state, :prefix => true, :allow_nil => true

  def full_address
    full_address = [address1, address2, zipcode, city, country.andand.name, state.andand.name]
    filtered_address = full_address.select{ |field| !field.nil? && field != '' }
    filtered_address.compact.join(', ')
  end


  private

  # We have a hard-to-track-down bug around invalid addresses with all-nil fields finding
  # their way into the database. I don't know what the source of them is, so this patch
  # is designed to track them down.
  # This is intended to be a temporary investigative measure, and should be removed from the
  # code base shortly. If it's past 17-10-2013, take it out.
  #
  #-- Rohan, 17-9-2913
  def create
    if self.zipcode.nil?
      Bugsnag.notify RuntimeError.new('Creating a Spree::Address with nil values')
    end

    super
  end

  def update(attribute_names = @attributes.keys)
    if self.zipcode.nil?
      Bugsnag.notify RuntimeError.new('Updating a Spree::Address with nil values')
    end

    super(attribute_names)
  end
end
