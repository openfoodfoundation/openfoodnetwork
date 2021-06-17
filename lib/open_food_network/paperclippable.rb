# frozen_string_literal: true

# Allow use of Paperclip's has_attached_file on non-ActiveRecord classes
# https://gist.github.com/basgys/5712426

module OpenFoodNetwork
  module Paperclippable
    def self.included(base)
      base.extend(ActiveModel::Naming)
      base.extend(ActiveModel::Callbacks)
      base.include(ActiveModel::Validations)
      base.include(Paperclip::Glue)

      # Paperclip required callbacks
      base.define_model_callbacks(:save, only: [:after])
      base.define_model_callbacks(:commit, only: [:after])
      base.define_model_callbacks(:destroy, only: [:before, :after])

      # Initialise an ID
      base.__send__(:attr_accessor, :id)
      base.instance_variable_set :@id, 1
    end

    # ActiveModel requirements
    def to_model
      self
    end

    def valid?()      true end

    def new_record?() true end

    def destroyed?()  true end

    def save
      run_callbacks :save do
      end
      true
    end

    def errors
      obj = Object.new
      def obj.[](_key) [] end

      def obj.full_messages() [] end

      def obj.any?() false end
      obj
    end
  end
end
