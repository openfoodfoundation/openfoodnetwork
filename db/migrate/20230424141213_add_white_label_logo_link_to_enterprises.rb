class AddWhiteLabelLogoLinkToEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :white_label_logo_link, :text, default: nil
  end
end
