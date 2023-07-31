# frozen_string_literal: true

require 'spree/responder'

module ActionController
  class Base
    def respond_with(*resources, &)
      if self.class.mimes_for_respond_to.empty?
        raise "In order to use respond_with, first you need to declare the formats your " \
              "controller responds to in the class level"
      end

      return unless (collector = retrieve_collector_from_mimes(&))

      options = resources.size == 1 ? {} : resources.extract_options!

      # Fix spree issues #3531 and #2210 (patch provided by leiyangyou)
      if (defined_response = collector.response) &&
         !ApplicationController.spree_responders[self.class.to_s.to_sym].try(:[],
                                                                             action_name.to_sym)
        if action = options.delete(:action)
          render action: action
        else
          defined_response.call
        end
      else
        # The action name is needed for processing
        options[:action_name] = action_name.to_sym
        # If responder is not specified then pass in Spree::Responder
        (options.delete(:responder) || Spree::Responder).call(self, resources, options)
      end
    end

    private

    def retrieve_collector_from_mimes(mimes = nil, &block)
      mimes ||= collect_mimes_from_class_level
      collector = Collector.new(mimes, request.variant)
      block.call(collector) if block_given?
      format = collector.negotiate_format(request)

      if format
        _process_format(format)
        collector
      else
        raise ActionController::UnknownFormat
      end
    end
  end
end

module Spree
  module Core
    module ControllerHelpers
      module RespondWith
        extend ActiveSupport::Concern

        included do
          cattr_accessor :spree_responders
          self.spree_responders = {}
        end

        module ClassMethods
          def clear_overrides!
            self.spree_responders = {}
          end

          def respond_override(options = {})
            return if options.blank?

            action_name = options.keys.first
            action_value = options.values.first

            if action_name.blank? || action_value.blank?
              raise ArgumentError, "invalid values supplied #{options.inspect}"
            end

            format_name = action_value.keys.first
            format_value = action_value.values.first

            if format_name.blank? || format_value.blank?
              raise ArgumentError, "invalid values supplied #{options.inspect}"
            end

            if format_value.is_a?(Proc)
              options = {
                action_name.to_sym => { format_name.to_sym => { success: format_value } }
              }
            end

            spree_responders.deep_merge!(name.to_sym => options)
          end
        end
      end
    end
  end
end
