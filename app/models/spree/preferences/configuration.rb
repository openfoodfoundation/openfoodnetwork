# frozen_string_literal: true

# This takes the preferrable methods and adds some
# syntatic sugar to access the preferences
#
# class App < Configuration
#   preference :color, :string
# end
#
# a = App.new
#
# setters:
# a.color = :blue
# a[:color] = :blue
# a.set :color = :blue
# a.preferred_color = :blue
#
# getters:
# a.color
# a[:color]
# a.get :color
# a.preferred_color
#
#
module Spree
  module Preferences
    class Configuration
      include Spree::Preferences::Preferable

      class << self
        def preference(name, type, *args)
          super

          define_method(name) do
            get_preference(name)
          end

          define_method("#{name}=") do |value|
            set_preference(name, value)
          end
        end
      end

      def configure
        yield(self) if block_given?
      end

      def preference_cache_key(name)
        [ENV.fetch('RAILS_CACHE_ID', nil), self.class.name, name].flatten.join('::').underscore
      end

      def reset
        preferences.each_key do |name|
          set_preference name, preference_default(name)
        end
      end

      alias :[] :get_preference
      alias :[]= :set_preference

      alias :get :get_preference

      def set(*args)
        options = args.extract_options!
        options.each do |name, value|
          set_preference name, value
        end

        return unless args.size == 2

        set_preference args[0], args[1]
      end
    end
  end
end
