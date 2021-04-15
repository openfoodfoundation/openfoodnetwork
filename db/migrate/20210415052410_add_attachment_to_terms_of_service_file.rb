# frozen_string_literal: true

class AddAttachmentToTermsOfServiceFile < ActiveRecord::Migration[5.0]
  def up
    add_attachment :terms_of_service_files, :attachment
  end

  def down
    remove_attachment :terms_of_service_files, :attachment
  end
end
