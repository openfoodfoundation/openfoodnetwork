module Spree
  Adjustment.class_eval do
    # Deletion of metadata is handled in the database.
    # So we don't need the option `dependent: :destroy` as long as
    # AdjustmentMetadata has no destroy logic itself.
    has_one :metadata, class_name: 'AdjustmentMetadata'
    belongs_to :tax_rate, foreign_key: 'originator_id', conditions: "spree_adjustments.originator_type = 'Spree::TaxRate'"

    scope :enterprise_fee,  where(originator_type: 'EnterpriseFee')
    scope :billable_period, where(source_type: 'BillablePeriod')
    scope :admin,           where(source_type: nil, originator_type: nil)
    scope :included_tax,    where(originator_type: 'Spree::TaxRate', adjustable_type: 'Spree::LineItem')

    scope :with_tax,        where('spree_adjustments.included_tax > 0')
    scope :without_tax,     where('spree_adjustments.included_tax = 0')
    scope :payment_fee,     where(originator_type: 'Spree::PaymentMethod')

    attr_accessible :included_tax

    def set_included_tax!(rate)
      tax = amount - (amount / (1 + rate))
      set_absolute_included_tax! tax
    end

    def set_absolute_included_tax!(tax)
      update_attributes! included_tax: tax.round(2)
    end

    def display_included_tax
      Spree::Money.new(included_tax, { :currency => currency })
    end

    def has_tax?
      included_tax > 0
    end

    # @return [Array<Spree::TaxRate>]
    def tax_rates
      case originator
      when Spree::TaxRate
        [originator]
      when EnterpriseFee
        case source
        when Spree::LineItem
          tax_category = originator.inherits_tax_category? ? source.product.tax_category : originator.tax_category
          return tax_category ? tax_category.tax_rates.match(source.order) : []
        when Spree::Order
          return originator.tax_category ? originator.tax_category.tax_rates.match(source) : []
        end
      else
        find_closest_tax_rates_from_included_tax
      end
    end

    # shipping fees and adjustments created from the admin panel have
    # taxes set at creation in the included_tax field without relation
    # to the corresponding TaxRate, so we look for the closest one
    def find_closest_tax_rates_from_included_tax
      approximation = (included_tax / (amount - included_tax))
      return [] if approximation.infinite? or approximation.zero?
      [Spree::TaxRate.order("ABS(amount - #{approximation})").first]
    end

    def self.without_callbacks
      skip_callback :save, :after, :update_adjustable
      skip_callback :destroy, :after, :update_adjustable

      result = yield

    ensure
      set_callback :save, :after, :update_adjustable
      set_callback :destroy, :after, :update_adjustable

      result
    end

  end
end
