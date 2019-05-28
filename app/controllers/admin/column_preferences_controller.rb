module Admin
  class ColumnPreferencesController < ResourceController
    before_filter :load_collection, only: [:bulk_update]

    respond_to :json

    def bulk_update
      @cp_set.collection.each { |cp| authorize! :bulk_update, cp }

      if @cp_set.save
        # Return saved VOs with IDs
        render json: @cp_set.collection, each_serializer: Api::Admin::ColumnPreferenceSerializer
      else
        if @cp_set.errors.present?
          render json: { errors: @cp_set.errors }, status: :bad_request
        else
          render nothing: true, status: :internal_server_error
        end
      end
    end

    private

    def load_collection
      collection_hash = Hash[params[:column_preferences].each_with_index.map { |cp, i| [i, cp] }]
      collection_hash.select!{ |_i, cp| cp[:action_name] == params[:action_name] }
      @cp_set = ColumnPreferenceSet.new @column_preferences, collection_attributes: collection_hash
    end

    def collection
      ColumnPreference.where(user_id: spree_current_user, action_name: params[:action_name])
    end

    def collection_actions
      [:bulk_update]
    end
  end
end
