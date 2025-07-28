# frozen_string_literal: true

class EnableFeatureInventoryForExistingEnterprises < ActiveRecord::Migration[7.0]
  # rubocop:disable Naming/VariableNumber
  def up
    Flipper.enable_group(:inventory, :enterprise_created_before_2025_08_11)
  end

  def down
    Flipper.disable_group(:inventory, :enterprise_created_before_2025_08_11)
  end
  # rubocop:enable Naming/VariableNumber
end
