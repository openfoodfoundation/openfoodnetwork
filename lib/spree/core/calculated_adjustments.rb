# frozen_string_literal: true

module Spree
  module Core
    module CalculatedAdjustments
      def self.included(klass)
        klass.class_eval do
          has_one :calculator, class_name: "Spree::Calculator", as: :calculable, dependent: :destroy
          accepts_nested_attributes_for :calculator
          validates :calculator, presence: true

          def self.calculators
            spree_calculators.__send__(model_name_without_spree_namespace)
          end

          def calculator_type
            calculator.class.to_s if calculator
          end

          def calculator_type=(calculator_type)
            klass = calculator_type.constantize if calculator_type
            self.calculator = klass.new if klass && !calculator.is_a?(klass)
          end

          def self.model_name_without_spree_namespace
            to_s.tableize.gsub('/', '_').sub('spree_', '')
          end
          private_class_method :model_name_without_spree_namespace

          def self.spree_calculators
            Rails.application.config.spree.calculators
          end
          private_class_method :spree_calculators
        end
      end
    end
  end
end
