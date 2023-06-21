# frozen_string_literal: true

require 'spec_helper'

describe Admin::ColumnPreferencesController, type: :controller do
  include AuthenticationHelper

  describe "bulk_update" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:enterprise) { create(:enterprise, owner: user1, users: [user1, user2]) }

    context "json" do
      let!(:column_preference) {
        ColumnPreference.create(user_id: user1.id, action_name: 'enterprises_index',
                                column_name: "name", visible: true)
      }

      let(:column_preference_params) {
        [
          { id: column_preference.id, user_id: user1.id, action_name: "enterprises_index",
            column_name: 'name', visible: false },
          { id: nil, user_id: user1.id, action_name: "enterprises_index", column_name: 'producer',
            visible: true },
          { id: nil, user_id: user1.id, action_name: "enterprises_index", column_name: 'status',
            visible: true }
        ]
      }

      context "where I don't own the preferences submitted" do
        before do
          allow(controller).to receive(:spree_current_user) { user2 }
        end

        it "prevents me from updating the column preferences" do
          spree_put :bulk_update, format: :json, action_name: "enterprises_index",
                                  column_preferences: column_preference_params
          expect(ColumnPreference.count).to be 1
        end
      end

      context "where I own the preferences submitted" do
        before do
          allow(controller).to receive(:spree_current_user) { user1 }
        end

        it "allows me to update the column preferences" do
          spree_put :bulk_update, format: :json, action_name: "enterprises_index",
                                  column_preferences: column_preference_params
          expect(ColumnPreference.where(user_id: user1.id,
                                        action_name: 'enterprises_index').count).to be 3
        end
      end
    end
  end
end
