# frozen_string_literal: true

class EnableVariantTagsForNewEnterprises < ActiveRecord::Migration[7.1]
  # rubocop:disable Naming/VariableNumber
  def up
    Flipper.enable_group(:variant_tag, :enterprise_created_after_2025_08_11)
  end

  def down
    Flipper.disable_group(:variant_tag, :enterprise_created_after_2025_08_11)
  end
  # rubocop:enable Naming/VariableNumber
end
