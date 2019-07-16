module LineItemBasedAdjustmentHandling
  extend ActiveSupport::Concern

  included do
    has_many :adjustments_for_which_source, class_name: "Spree::Adjustment", as: :source,
                                            dependent: :destroy
  end
end
