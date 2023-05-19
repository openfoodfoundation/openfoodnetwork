# frozen_string_literal: true

require 'spec_helper'

describe Admin::ProductImportController, type: :controller do
  describe 'validate_file_path' do
    context 'file extension' do
      it 'should authorize csv extension' do
        path = '/tmp/product_import123/import.csv'
        expect(controller.__send__(:validate_file_path, path)).to be_truthy
      end

      it 'should reject other extensions' do
        allow(controller).to receive(:raise_invalid_file_path).and_return(false)
        path = '/tmp/product_import123/import.pdf'
        expect(controller.__send__(:validate_file_path, path)).to be_falsey
        path1 = '/tmp/product_import123/import.xslx'
        expect(controller.__send__(:validate_file_path, path1)).to be_falsey
      end
    end

    context 'folder path' do
      it 'should authorize valid paths' do
        path = '/tmp/product_import123/import.csv'
        expect(controller.__send__(:validate_file_path, path)).to be_truthy
        path1 = '/tmp/product_importabc/import.csv'
        expect(controller.__send__(:validate_file_path, path1)).to be_truthy
        path2 = '/tmp/product_importABC-abc-123/import.csv'
        expect(controller.__send__(:validate_file_path, path2)).to be_truthy
      end

      it 'should reject invalid paths' do
        allow(controller).to receive(:raise_invalid_file_path).and_return(false)
        path = '/tmp/product_import123/../etc/import.csv'
        expect(controller.__send__(:validate_file_path, path)).to be_falsey

        path1 = '/tmp/product_import../etc/import.csv'
        expect(controller.__send__(:validate_file_path, path1)).to be_falsey

        path2 = '/tmp/product_import132%2F..%2Fetc%2F/import.csv'
        expect(controller.__send__(:validate_file_path, path2)).to be_falsey

        path3 = '/etc/tmp/product_import123/import.csv'
        expect(controller.__send__(:validate_file_path, path3)).to be_falsey
      end
    end
  end
end
