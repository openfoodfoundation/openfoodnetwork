  Deface::Override.new(:virtual_path => "spree/admin/general_settings/edit",
					 :name => "add_display_preferece_to_state",
					 :insert_before => "[data-hook='buttons']",
					 :partial => 'spree/admin/general_settings/state_display_preference_form')