# frozen_string_literal: true

RSpec.describe 'ofn:import:product_images' do
  describe 'task' do
    context "filename is blank" do
      it 'raises an error' do
        expect {
          invoke_task('ofn:import:product_images')
        }.to raise_error(RuntimeError,
                         'Filename required')
      end
    end

    context "invalid CSV format" do
      it 'raises an error if CSV columns are missing' do
        allow(CSV).to receive(:read).and_return(CSV::Table.new([]))

        expect {
          invoke_task('ofn:import:product_images["path/to/csv/file.csv"]')
        }.to raise_error(RuntimeError, 'CSV columns reqired: ["producer", "name", "image_url"]')
      end
    end

    context "valid CSV" do
      it 'imports images for each product in the CSV that exists and does not have images' do
        filename = 'path/to/csv/file.csv'

        csv_data = [
          { producer: 'Producer 1', name: 'Product 1', image_url: 'http://example.com/image1.jpg' },
          { producer: 'Producer 2', name: 'Product 2', image_url: 'http://example.com/image2.jpg' },
          { producer: 'Producer 3', name: 'Product 3', image_url: 'http://example.com/image3.jpg' }
        ]

        csv_rows = csv_data.map do |hash|
          CSV::Row.new(hash.keys, hash.values)
        end

        csv_table = CSV::Table.new(csv_rows)

        allow(CSV).to receive(:read).and_return(csv_table)

        allow(Enterprise).to receive(:find_by!).with(name: 'Producer 1').and_return(double)
        allow(Enterprise).to receive(:find_by!).with(name: 'Producer 2').and_return(double)
        allow(Enterprise).to receive(:find_by!).with(name: 'Producer 3').and_return(double)

        allow(Spree::Product).to receive(:where).and_return(
          class_double('Spree::Product', first: nil),
          class_double('Spree::Product', first: instance_double('Spree::Product', image: nil)),
          class_double('Spree::Product', first: instance_double('Spree::Product', image: true))
        )

        allow_any_instance_of(ImageImporter).to receive(:import).and_return(true)

        expected_output = <<~OUTPUT
          Warning: use only with trusted URLs. This script will download whatever it can, including local secrets, and expose the file as an image file.
          0 Producer 1, Product 1
           product not found.
          1 Producer 2, Product 2
           image added.
          2 Producer 3, Product 3
           image exists, not updated.
        OUTPUT

        expect {
          invoke_task('ofn:import:product_images["path/to/csv/file.csv"]')
        }.to output(expected_output).to_stdout
      end
    end
  end
end
