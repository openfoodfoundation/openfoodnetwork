# frozen_string_literal: true

module Spree
  module Core
    module EnvironmentExtension
      extend ActiveSupport::Concern

      def add_class(name)
        instance_variable_set "@#{name}", Set.new

        create_method( "#{name}=".to_sym ) { |val|
          instance_variable_set( "@" + name, val)
        }

        create_method(name.to_sym) do
          instance_variable_get( "@" + name )
        end
      end

      private

      def create_method(name, &)
        self.class.__send__(:define_method, name, &)
      end
    end
  end
end
