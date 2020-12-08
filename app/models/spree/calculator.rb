# frozen_string_literal: true

module Spree
  class Calculator < ActiveRecord::Base
    belongs_to :calculable, polymorphic: true

    # This method must be overriden in concrete calculator.
    #
    # It should return amount computed based on #calculable and/or optional parameter
    def compute(computable = nil)
      # Spree::LineItem -> :compute_line_item
      computable_name = computable.class.name.demodulize.underscore
      method = "compute_#{computable_name}".to_sym
      calculator_class = self.class
      if respond_to?(method)
        self.send(method, computable)
      else
        raise NotImplementedError, "Please implement '#{method}(#{computable_name})' in your calculator: #{calculator_class.name}"
      end
    end

    # overwrite to provide description for your calculators
    def self.description
      'Base Calculator'
    end

    ###################################################################

    def self.register(*klasses); end

    # Returns all calculators applicable for kind of work
    def self.calculators
      Rails.application.config.spree.calculators
    end

    def to_s
      self.class.name.titleize.gsub("Calculator\/", "")
    end

    def description
      self.class.description
    end

    def available?(_object)
      true
    end

    private

    # Given an object which might be an Order or a LineItem (amongst
    # others), return a collection of line items.
    def line_items_for(object)
      if object.is_a?(Spree::LineItem)
        [object]
      elsif object.respond_to? :line_items
        object.line_items
      elsif object.respond_to?(:order) && object.order.present?
        object.order.line_items
      else
        [object]
      end
    end
  end
end
