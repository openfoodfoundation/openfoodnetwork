class RemoveReportInverseColumnsLogicFeatureToggleKey < ActiveRecord::Migration[6.1]
  def change
    # Remove the feature toggle key for the report inverse columns logic
    # since it is now enabled by default. This should have been done 
    # in the PR #9830, but was missed.
    execute("DELETE FROM flipper_gates WHERE feature_key = 'report_inverse_columns_logic'")
    execute("DELETE FROM flipper_features WHERE key = 'report_inverse_columns_logic'")
  end
end
