# frozen_string_literal: true

RSpec.describe Admin::ProductImportController do
  describe "#import" do
    context "when importing into inventory with inventory disabled" do
      it "redirect with an error" do
        allow(controller).to receive(:spree_current_user).and_return(create(:admin_user))
        allow(controller).to receive(:validate_upload_presence).and_return(true)

        spree_post :import, { settings: { import_into: "inventories" } }

        expect(response).to redirect_to admin_product_import_url
        expect(flash[:notice]).to eq "Importing into inventories is not available"
      end
    end
  end

  describe 'validate_file_path' do
    let(:tmp_directory_base) { Rails.root.join("tmp/product_import-") }

    before do
      # Avoid error on redirect_to
      allow(controller).to receive(:raise_invalid_file_path).and_return(false)
    end

    context 'file extension' do
      it 'should authorize csv extension' do
        path = "#{tmp_directory_base}123/import.csv"
        expect(controller.__send__(:validate_file_path, path)).to be_truthy
      end

      it 'should reject other extensions' do
        path = "#{tmp_directory_base}123/import.pdf"
        expect(controller.__send__(:validate_file_path, path)).to be_falsey
        path1 = "#{tmp_directory_base}123/import.xslx"
        expect(controller.__send__(:validate_file_path, path1)).to be_falsey
      end
    end

    context 'folder path' do
      it 'should authorize valid paths' do
        path = "#{tmp_directory_base}123/import.csv"
        expect(controller.__send__(:validate_file_path, path)).to be_truthy
        path1 = "#{tmp_directory_base}abc/import.csv"
        expect(controller.__send__(:validate_file_path, path1)).to be_truthy
        path2 = "#{tmp_directory_base}ABC-abc-123/import.csv"
        expect(controller.__send__(:validate_file_path, path2)).to be_truthy
      end

      it 'should reject invalid paths' do
        path = "#{tmp_directory_base}123/../etc/import.csv"
        expect(controller.__send__(:validate_file_path, path)).to be_falsey

        path1 = "#{tmp_directory_base}../etc/import.csv"
        expect(controller.__send__(:validate_file_path, path1)).to be_falsey

        path2 = "#{tmp_directory_base}132%2F..%2Fetc%2F/import.csv"
        expect(controller.__send__(:validate_file_path, path2)).to be_falsey

        path3 = "/etc#{tmp_directory_base}123/import.csv"
        expect(controller.__send__(:validate_file_path, path3)).to be_falsey
      end
    end
  end
end
