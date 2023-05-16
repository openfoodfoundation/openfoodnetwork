# frozen_string_literal: true

require 'spec_helper'

describe FilePathSanitizer do
  let(:folder_path){ '/tmp/product_import123' }
  let(:file_path) { "#{folder_path}/import.csv" }

  before do
    FileUtils.mkdir_p(folder_path)
    File.new(file_path, 'w') unless File.exist?(file_path)
  end
  let(:object) { described_class.new }

  it 'should covert relative path to absolute' do
    path = "/tmp/product_import123/import.csv"
    expect(object.sanitize(path).to_s).to eq file_path

    path1 = "/../../tmp/product_import123/import.csv"
    expect(object.sanitize(path1).to_s).to eq file_path

    path2 = "/etc/../../../tmp/product_import123/import.csv"
    expect(object.sanitize(path2).to_s).to eq file_path
  end

  it "call errors callback if the file doesn't exist" do
    path = '/tmp/product_import123/import1.csv'
    error_callback = double('error_callback')
    expect(error_callback).to receive(:call)

    expect( object.sanitize(path, on_error: error_callback) ).to eq(false)
  end
end
