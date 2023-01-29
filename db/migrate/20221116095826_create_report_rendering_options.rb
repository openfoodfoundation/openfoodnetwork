class CreateReportRenderingOptions < ActiveRecord::Migration[6.1]
  def change
    create_table :report_rendering_options do |t|
      t.references :user
      t.text :options
      t.string :report_type
      t.string :report_subtype

      t.timestamps
    end
  end
end
