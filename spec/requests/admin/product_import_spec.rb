# frozen_string_literal: true

require 'spec_helper'

describe "Product Import", type: :request do
  include AuthenticationHelper

  describe "validate_data" do
    it "requires a login" do
      post admin_product_import_process_async_path

      expect(response).to redirect_to %r|#/login$|
    end

    it "raises an error on non-csv files" do
      login_as_admin

      expect do
        post admin_product_import_process_async_path, params: {
          filepath: "/etc/passwd",
        }, as: :json
      end
        .to raise_error "Invalid File Path"

      # The user just sees a server error.
    end

    it "raises an error when csv file doesn't exist" do
      login_as_admin

      expect do
        post admin_product_import_process_async_path, params: {
          filepath: "/file/does/not/exist.csv",
        }, as: :json
      end
        .to raise_error "Invalid File Path"

      # The user just sees a server error.
    end

    it "raises an error non unauthorized csv file" do
      login_as_admin

      # This could point to a secret file in the file system:
      existing_file = Rails.public_path.join('inventory_template.csv').to_s

      expect do
        post admin_product_import_process_async_path, params: {
          filepath: existing_file,
          start: 1,
          end: 5,
        }, as: :json
      end
        .to raise_error "Invalid File Path"

      # The user just sees a server error.
    end

    it "raises an error on valid but missing csv file" do
      login_as_admin

      # This could point to a secret file in the file system:
      directory = Dir.mktmpdir("product_import")
      missing_valid_file = File.join(directory, "import.csv").to_s

      expect do
        post admin_product_import_process_async_path, params: {
          filepath: missing_valid_file,
          start: 1,
          end: 5,
        }, as: :json
      end
        .to raise_error "Invalid File Path"

      # The user just sees a server error.
    end
  end
end
