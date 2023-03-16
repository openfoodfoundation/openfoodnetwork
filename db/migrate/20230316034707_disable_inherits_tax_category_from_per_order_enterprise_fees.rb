# frozen_string_literal: true

class DisableInheritsTaxCategoryFromPerOrderEnterpriseFees < ActiveRecord::Migration[6.1]
  class EnterpriseFee < ApplicationRecord
    has_one :calculator, as: :calculable, class_name: "Spree::Calculator", dependent: :destroy
  end

  class Spree
    class Calculator < ApplicationRecord
      self.table_name = 'spree_calculators'
    end
  end

  def change
    EnterpriseFee.joins(:calculator).merge(calculators)
      .where(inherits_tax_category: true)
      .update_all(inherits_tax_category: false)
  end

  def calculators
    Spree::Calculator.where(type: per_order_calculators)
  end

  def per_order_calculators
    ['Calculator::FlatRate',
     'Calculator::FlexiRate',
     'Calculator::PriceSack']
  end
end
