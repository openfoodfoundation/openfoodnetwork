# frozen_string_literal: true

module Admin
  class ColumnPreferencesController < Admin::ResourceController
    before_action :load_collection, only: [:bulk_update]

    respond_to :json

    def bulk_update
      @cp_set.collection.each { |cp| authorize! :bulk_update, cp }

      if @cp_set.save
        render json: @cp_set.collection, each_serializer: Api::Admin::ColumnPreferenceSerializer
      elsif @cp_set.errors.present?
        render json: { errors: @cp_set.errors }, status: :bad_request
      else
        render body: nil, status: :internal_server_error
      end
    end

    private

    def permitted_params
      params.permit(
        :action_name,
        column_preferences: [:id, :user_id, :action_name, :column_name, :name, :visible]
      )
    end

    def load_collection
      collection_hash = Hash[permitted_params[:column_preferences].
        each_with_index.map { |cp, i| [i, cp] }]
      collection_hash.select!{ |_i, cp| cp[:action_name] == permitted_params[:action_name] }
      @cp_set = Sets::ColumnPreferenceSet.new(@column_preferences,
                                              collection_attributes: collection_hash)
    end

    def collection
      ColumnPreference.where(user_id: spree_current_user,
                             action_name: permitted_params[:action_name])
    end

    def collection_actions
      [:bulk_update]
    end
  end
end
