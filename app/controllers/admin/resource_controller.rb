# frozen_string_literal: true

module Admin
  class ResourceController < Spree::Admin::BaseController
    helper_method :new_object_url, :edit_object_url, :object_url, :collection_url
    before_action :load_resource, except: [:update_positions]
    rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found
    rescue_from CanCan::AccessDenied, with: :unauthorized

    respond_to :html
    respond_to :js, except: [:show, :index]

    def new
      respond_with(@object) do |format|
        format.html { render layout: !request.xhr? }
        format.js   { render layout: false }
      end
    end

    def edit
      respond_with(@object) do |format|
        format.html { render layout: !request.xhr? }
        format.js   { render layout: false }
      end
    end

    def create
      @object.attributes = permitted_resource_params
      if @object.save
        flash[:success] = flash_message_for(@object, :successfully_created)
        respond_with(@object) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render layout: false }
        end
      else
        respond_with(@object)
      end
    end

    def update
      if @object.update(permitted_resource_params)
        flash[:success] = flash_message_for(@object, :successfully_updated)
        respond_with(@object) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render layout: false }
        end
      else
        respond_with(@object)
      end
    end

    def update_positions
      params[:positions].each do |id, index|
        model_class.where(id:).update_all(position: index)
      end

      respond_to do |format|
        format.js { render plain: 'Ok' }
      end
    end

    def destroy
      if @object.destroy
        flash[:success] = flash_message_for(@object, :successfully_removed)
        respond_with(@object) do |format|
          format.html { redirect_to collection_url }
          format.js   { render partial: "spree/admin/shared/destroy" }
        end
      else
        respond_with(@object) do |format|
          format.html { redirect_to collection_url }
        end
      end
    end

    protected

    def resource_not_found
      flash[:error] = Spree.t(:not_found, resource: model_class.model_name.human)
      redirect_to collection_url
    end

    class << self
      attr_accessor :parent_data

      def belongs_to(model_name, options = {})
        @parent_data ||= {}
        @parent_data[:model_name] = model_name
        @parent_data[:model_class] = model_name.to_s.classify.constantize
        @parent_data[:find_by] = options[:find_by] || :id
      end
    end

    def model_class
      controller_class_name.constantize
    end

    def model_name
      parent_data[:model_name].gsub('spree/', '')
    end

    def object_name
      controller_name.singularize
    end

    def load_resource
      if member_action?
        @object ||= load_resource_instance

        # call authorize! a third time (called twice already in Admin::BaseController)
        # this time we pass the actual instance so fine-grained abilities can control
        # access to individual records, not just entire models.
        authorize! action, @object

        instance_variable_set("@#{object_name}", @object)

        # If we don't have access, clear the object
        unless can? action, @object
          instance_variable_set("@#{object_name}", nil)
        end

        authorize! action, @object
      else
        @collection ||= collection

        # note: we don't call authorize here as the collection method should use
        # CanCan's accessible_by method to restrict the actual records returned

        instance_variable_set("@#{controller_name}", @collection)
      end
    end

    def load_resource_instance
      if new_actions.include?(action)
        build_resource
      elsif params[:id]
        find_resource
      end
    end

    def parent_data
      self.class.parent_data
    end

    def parent
      return nil if parent_data.blank?

      @parent ||= parent_data[:model_class].
        find_by(parent_data[:find_by] => params["#{model_name}_id"])
      instance_variable_set("@#{model_name}", @parent)
    end

    def find_resource
      if parent_data.present?
        parent.public_send(controller_name).find(params[:id])
      else
        model_class.find(params[:id])
      end
    end

    def build_resource
      if parent_data.present?
        parent.public_send(controller_name).build
      else
        model_class.new
      end
    end

    def collection
      return parent.public_send(controller_name) if parent_data.present?

      if model_class.respond_to?(:accessible_by) &&
         !current_ability.has_block?(params[:action], model_class)
        model_class.accessible_by(current_ability, action)
      else
        model_class.scoped
      end
    end

    def location_after_save
      collection_url
    end

    # URL helpers
    def new_object_url(options = {})
      if parent_data.present?
        url_helper.new_polymorphic_url([:admin, parent, model_class], options)
      else
        url_helper.new_polymorphic_url([:admin, model_class], options)
      end
    end

    def edit_object_url(object, options = {})
      if parent_data.present?
        url_helper.public_send "edit_admin_#{model_name}_#{object_name}_url",
                               parent, object, options
      else
        url_helper.public_send "edit_admin_#{object_name}_url",
                               object, options
      end
    end

    def object_url(object = nil, options = {})
      target = object || @object
      if parent_data.present?
        url_helper.public_send "admin_#{model_name}_#{object_name}_url", parent, target, options
      else
        url_helper.public_send "admin_#{object_name}_url", target, options
      end
    end

    # Permit specific list of params
    #
    # Example: params.require(object_name).permit(:name)
    def permitted_resource_params
      raise "All extending controllers need to override the method permitted_resource_params"
    end

    def collection_url(options = {})
      if parent_data.present?
        url_helper.polymorphic_url([:admin, parent, model_class], options)
      else
        url_helper.polymorphic_url([:admin, model_class], options)
      end
    end

    def collection_actions
      [:index]
    end

    def member_action?
      collection_actions.exclude? action
    end

    def new_actions
      [:new, :create]
    end

    private

    def controller_class_name
      if spree_controller?
        "Spree::#{controller_name.classify}"
      else
        controller_name.classify.to_s
      end
    end

    def url_helper
      if spree_controller?
        spree
      else
        main_app
      end
    end

    def spree_controller?
      controller_path.starts_with? "spree"
    end
  end
end
