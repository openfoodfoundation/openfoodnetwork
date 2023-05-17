# frozen_string_literal: true

require 'spec_helper'

describe "Product Import", type: :request do
  include AuthenticationHelper

  describe "validate_data" do
    it "requires a login" do
      post admin_product_import_process_async_path

      expect(response).to redirect_to %r|#/login$|
    end

    it "rejects non-csv files" do
      login_as_admin

      post admin_product_import_process_async_path, params: {
        filepath: "/etc/passwd",
      }, as: :json

      expect(response).to have_http_status :ok
      expect(response.body).to eq "undefined method `validate_all' for nil:NilClass"
    end

    it "raises an error when csv file doesn't exist" do
      login_as_admin

      expect do
        post admin_product_import_process_async_path, params: {
          filepath: "/file/does/not/exist.csv",
        }, as: :json
      end
        # This would result in server error and we know the file doesn't exist.
        .to raise_error(
          Errno::ENOENT,
          "No such file or directory @ rb_sysopen - /file/does/not/exist.csv"
        )
    end

    it "tries to read any csv file" do
      login_as_admin

      # This could point to a secret file in the file system:
      existing_file = Rails.public_path.join('inventory_template.csv').to_s

      post admin_product_import_process_async_path, params: {
        filepath: existing_file,
        start: 1,
        end: 5,
      }, as: :json

      # No error, the file exists:
      expect(response).to have_http_status :ok
      # But it doesn't contain product data:
      expect(response.body).to eq '{"entries":"{}","reset_counts":{}}'
    end
  end
end
