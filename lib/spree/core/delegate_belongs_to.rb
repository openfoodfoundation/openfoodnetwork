# frozen_string_literal: true

##
# Creates methods on object which delegate to an association proxy.
# see delegate_belongs_to for two uses
#
# Todo - integrate with ActiveRecord::Dirty to make sure changes to delegate object are noticed
# Should do
# class User < ActiveRecord::Base; delegate_belongs_to :contact, :firstname; end
# class Contact < ActiveRecord::Base; end
# u = User.first
# u.changed? # => false
# u.firstname = 'Bobby'
# u.changed? # => true
#
# Right now the second call to changed? would return false
#
# Todo - add has_one support. fairly straightforward addition
##
module DelegateBelongsTo
  extend ActiveSupport::Concern

  module ClassMethods
    @@default_rejected_delegate_columns = ['created_at', 'created_on', 'updated_at',
                                           'updated_on', 'lock_version', 'type', 'id',
                                           'position', 'parent_id', 'lft', 'rgt']
    mattr_accessor :default_rejected_delegate_columns

    ##
    # Creates methods for accessing and setting attributes on an association.  Uses same
    # default list of attributes as delegates_to_association.
    # delegate_belongs_to :contact
    # delegate_belongs_to :contact, [:defaults]  ## same as above, and useless
    # delegate_belongs_to :contact, [:defaults, :address, :fullname], :class_name => 'VCard'
    ##
    def delegate_belongs_to(association, *attrs)
      opts = attrs.extract_options!
      initialize_association :belongs_to, association, opts
      attrs = get_association_column_names(association) if attrs.empty?
      attrs.concat get_association_column_names(association) if attrs.delete :defaults
      attrs.each do |attr|
        class_def attr do |*args|
          if args.empty?
            __send__(:delegator_for, association).__send__(attr)
          else
            __send__(:delegator_for, association).__send__(attr, *args)
          end
        end
        class_def "#{attr}=" do |val|
          __send__(:delegator_for, association).__send__("#{attr}=", val)
        end
      end
    end

    protected

    def get_association_column_names(association, without_default_rejected_delegate_columns = true)
      association_klass = reflect_on_association(association).klass
      methods = association_klass.column_names
      if without_default_rejected_delegate_columns
        methods.reject!{ |x| default_rejected_delegate_columns.include?(x.to_s) }
      end
      methods
    rescue StandardError
      []
    end

    ##
    # initialize_association :belongs_to, :contact
    def initialize_association(type, association, opts = {})
      unless [:belongs_to].include?(type.to_s.to_sym)
        raise 'Illegal or unimplemented association type.'
      end

      __send__(type, association, **opts) if reflect_on_association(association).nil?
    end

    private

    def class_def(name, method = nil, &)
      class_eval { method.nil? ? define_method(name, &) : define_method(name, method) }
    end
  end

  def delegator_for(association)
    if __send__(association).nil?
      __send__("#{association}=", self.class.reflect_on_association(association).klass.new)
    end
    __send__(association)
  end
  protected :delegator_for
end
