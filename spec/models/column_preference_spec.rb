require 'spec_helper'

describe ColumnPreference, type: :model do
  describe "finding stored preferences for a user and action" do
    before do
      allow(ColumnPreference).to receive(:known_actions) { ['some_action'] }
      allow(ColumnPreference).to receive(:valid_columns_for) { ['col1', 'col2', 'col3'] }
    end

    let(:user) { create(:user) }
    let!(:col1_pref) { ColumnPreference.create(user_id: user.id, action_name: 'some_action', column_name: 'col1', visible: true) }
    let!(:col2_pref) { ColumnPreference.create(user_id: user.id, action_name: 'some_action', column_name: 'col2', visible: false) }
    let(:defaults) { {
      col1:   { name: "col1", visible: false },
      col2:   { name: "col2", visible: true },
      col3:   { name: "col3", visible: false },
    } }

    context "when the user has preferences stored for the given action" do
      before do
        allow(ColumnPreference).to receive(:some_action_columns) { defaults }
      end

      let(:preferences) { ColumnPreference.for(user, :some_action)}

      it "builds an entry for each column listed in the defaults" do
        expect(preferences.count).to eq 3
      end

      it "uses values from stored preferences where present" do
        expect(preferences).to include col1_pref, col2_pref
      end

      it "uses defaults where no stored preference exists" do
        default_pref = preferences.last
        expect(default_pref).to be_a_new ColumnPreference
        expect(default_pref.visible).to be false # As per default
      end
    end

    context "where the user does not have preferences stored for the given action" do
      before do
        allow(ColumnPreference).to receive(:some_action_columns) { defaults }
      end

      let(:preferences) { ColumnPreference.for(create(:user), :some_action)}

      it "builds an entry for each column listed in the defaults" do
        expect(preferences.count).to eq 3
      end

      it "uses defaults where no stored preference exists" do
        expect(preferences.all?(&:new_record?)).to be true
        expect(preferences.map(&:column_name)).to eq [:col1, :col2, :col3]
        expect(preferences.map(&:visible)).to eq [false, true, false]
      end
    end
  end
end
