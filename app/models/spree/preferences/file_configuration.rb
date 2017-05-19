module Spree::Preferences
  class FileConfiguration < Configuration

    def self.preference(name, type, *args)
      if type == :file
        super "#{name}_file_name",    :string,  *args
        super "#{name}_content_type", :string,  *args
        super "#{name}_file_size",    :integer, *args
        super "#{name}_updated_at",   :string,  *args

      else
        super name, type, *args
      end
    end

    def get_preference(key)
      if !has_preference?(key) && has_attachment?(key)
        send key
      else
        super key
      end
    end
    alias :[] :get_preference


    def preference_type(name)
      if has_attachment? name
        :file
      else
        super name
      end
    end

    # Spree's Configuration responds to preference methods via method_missing, but doesn't
    # override respond_to?, which consequently reports those methods as unavailable. Paperclip
    # errors if respond_to? isn't correct, so we override it here.
    def respond_to?(method, include_all=false)
      name = method.to_s.gsub('=', '')
      super(self.class.preference_getter_method(name), include_all) || super(method, include_all)
    end

    def has_attachment?(name)
      self.class.respond_to?(:attachment_definitions) &&
        self.class.attachment_definitions.keys.include?(name.to_sym)
    end
  end
end
