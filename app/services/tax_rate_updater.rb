# frozen_string_literal: true

# If a TaxRate is modified in production and the amount is changed, we need to clone
# and soft-delete it to preserve associated data on previous orders. For example; previous
# orders will have adjustments created with that rate. Those old orders will keep the
# rate they had when they were created, and new orders will have the new rate applied.

class TaxRateUpdater
  def initialize(current_rate, permitted_params)
    @current_rate = current_rate
    @permitted_params = permitted_params
  end

  def updated_rate
    @updated_rate ||= begin
      clone = clone_tax_rate!
      clone.assign_attributes(permitted_params)
      clone
    end
  end

  def transition_rate!
    ActiveRecord::Base.transaction do
      updated_rate.save && current_rate.destroy
    end
  end

  private

  attr_reader :current_rate, :permitted_params

  def clone_tax_rate!
    cloned_rate = current_rate.deep_dup
    cloned_rate.calculator = current_rate.calculator.deep_dup
    cloned_rate
  end
end
