module Spree
  module TestingSupport
    module ConfigStub
      def set_preference(name, value)
        has_preference! name
        @config[name.to_sym] = value
      end

      def get_preference(name)
        has_preference! name
        @config[name.to_sym] || super
      end

      alias :[] :get_preference
      alias :[]= :set_preference

      alias :get :get_preference

      def setup_config_stub!
        @config = {}
      end

      def reset_config_stub!
        @config.clear
      end
    end
  end
end
