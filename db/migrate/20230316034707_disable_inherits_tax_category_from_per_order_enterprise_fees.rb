# frozen_string_literal: true

class DisableInheritsTaxCategoryFromPerOrderEnterpriseFees < ActiveRecord::Migration[6.1]
  class EnterpriseFee < ApplicationRecord
    has_many :calculator, class_name: "Spree::Calculator", foreign_key: :calculable_id
  end

  module Spree
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
    Spree::Calculator.where(type: per_order_calculators, calculable_type: 'EnterpriseFee')
  end

  def per_order_calculators
    ['Calculator::FlatRate',
     'Calculator::FlexiRate',
     'Calculator::PriceSack']
  end
end
