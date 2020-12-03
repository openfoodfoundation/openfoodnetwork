module LineItemBasedAdjustmentHandling
  extend ActiveSupport::Concern

  # Needs looking at
  # This isn't present anywhere in Spree.
  # Actually, this doesn't seem to be directly called from anywhere... maybe just dead code. :fire:

  included do
    has_many :adjustments_for_which_source, class_name: "Spree::Adjustment", as: :source,
                                            dependent: :destroy
  end
end
