# frozen_string_literal: true

module Api
  module Admin
    module PaymentMethod
      class BaseSerializer < ActiveModel::Serializer
        attributes :id, :name, :type, :tag_list, :tags

        def tag_list
          payment_method_tag_list.join(",")
        end

        def tags
          payment_method_tag_list.map{ |t| { text: t } }
        end

        private

        def payment_method_tag_list
          return object.tag_list unless options[:payment_method_tags]

          options.dig(:payment_method_tags, object.id) || []
        end
      end
    end
  end
end
