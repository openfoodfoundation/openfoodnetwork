# frozen_string_literal: true

module Admin
  class ColumnPreferencesController < Admin::ResourceController
    before_action :load_collection, only: [:bulk_update]

    def bulk_update
      @cp_set.collection.each { |cp| authorize! :bulk_update, cp }

      respond_to do |format|
        if @cp_set.save
          format.json {
            render json: @cp_set.collection, each_serializer: Api::Admin::ColumnPreferenceSerializer
          }
          format.turbo_stream {
            flash.now[:success] = t('.success')
            render :bulk_update, locals: { action: permitted_params[:action_name] }
          }
        else
          format.json { render json: { errors: @cp_set.errors }, status: :bad_request }
          format.turbo_stream {
            flash.now[:error] = @cp_set.errors.full_messages.to_sentence
            render :bulk_update, locals: { action: permitted_params[:action_name] }
          }
        end
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
      collection_attributes = nil

      respond_to do |format|
        format.json do
          collection_attributes = permitted_params[:column_preferences].
            each_with_index.to_h { |cp, i| [i, cp] }
          collection_attributes.select!{ |_i, cp|
            cp[:action_name] == permitted_params[:action_name]
          }
        end
        format.all do
          # Inject action name and user ID for each column_preference
          collection_attributes = permitted_params[:column_preferences].to_h.each_value { |cp|
            cp[:action_name] = permitted_params[:action_name]
            cp[:user_id] = spree_current_user.id
          }
        end
      end

      @cp_set = Sets::ColumnPreferenceSet.new(@column_preferences, collection_attributes:)
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
