# frozen_string_literal: true

RSpec.describe Admin::ColumnPreferencesController do
  include AuthenticationHelper

  describe "bulk_update" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:enterprise) { create(:enterprise, owner: user1, users: [user1, user2]) }
    let!(:column_preference) {
      ColumnPreference.create(user_id: user1.id, action_name: 'enterprises_index',
                              column_name: "name", visible: true)
    }

    shared_examples "where I own the preferences submitted" do
      before do
        allow(controller).to receive(:spree_current_user) { user1 }
      end

      it "allows me to update the column preferences" do
        spree_put :bulk_update, format: request_format, action_name: "enterprises_index",
                                column_preferences: column_preference_params
        expect(ColumnPreference.where(user_id: user1.id,
                                      action_name: 'enterprises_index').count).to be 3
      end
    end

    context "json" do
      let(:request_format) { :json }
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

      it_behaves_like "where I own the preferences submitted"

      context "where I don't own the preferences submitted" do
        before do
          allow(controller).to receive(:spree_current_user) { user2 }
        end

        it "prevents me from updating the column preferences" do
          spree_put :bulk_update, format: request_format, action_name: "enterprises_index",
                                  column_preferences: column_preference_params
          expect(ColumnPreference.count).to be 1
        end
      end
    end

    context "turbo_stream" do
      let(:request_format) { :turbo_stream }
      let(:column_preference_params) {
        {
          '0': { id: column_preference.id, column_name: "name", visible: "0" },
          '1': { id: nil, column_name: "producer", visible: "1" },
          '2': { id: nil, column_name: "status", visible: "1" },
        }
      }

      it_behaves_like "where I own the preferences submitted"

      context "where I don't own the preferences submitted" do
        before do
          allow(controller).to receive(:spree_current_user) { user2 }
        end

        # This has the same effect as the JSON action, but due to differing implementation,
        # it has different expections.
        it "prevents me from updating the column preferences" do
          expect {
            spree_put :bulk_update, format: request_format, action_name: "enterprises_index",
                                    column_preferences: column_preference_params
          }.to raise_error(ActiveRecord::RecordNotUnique)

          expect(column_preference.reload.visible).to eq true
        end
      end
    end
  end
end
