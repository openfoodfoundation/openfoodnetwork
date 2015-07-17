module Spree::Preferences
  class FileConfiguration < Configuration

    # Ideally, we'd alias_method_chain preference to add new type. However, failcake.
    def self.file_preference(name)
      preference "#{name}_file_name",    :string
      preference "#{name}_content_type", :string
      preference "#{name}_file_size",    :integer
      preference "#{name}_updated_at",   :string
    end


    # TODO: Rewrite with super

    def get_preference_with_files(key)
      if !has_preference?(key) && has_attachment?(key)
        send(key)
      else
        get_preference_without_files(key)
      end
    end
    alias_method_chain :get_preference, :files
    alias :[] :get_preference


    def preference_type_with_files(name)
      if has_attachment? name
        :file
      else
        preference_type_without_files(name)
      end
    end
    alias_method_chain :preference_type, :files


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
