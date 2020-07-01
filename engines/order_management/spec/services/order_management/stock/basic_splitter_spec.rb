# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Stock
    describe BasicSplitter do
      let(:packer) { build(:stock_packer) }

      it 'continues to splitter chain' do
        splitter1 = BasicSplitter.new(packer)
        splitter2 = BasicSplitter.new(packer, splitter1)
        packages = []

        expect(splitter1).to receive(:split).with(packages)
        splitter2.split(packages)
      end

      it 'builds package using package factory' do
        # Basic extension of Base splitter used to test build_package method
        class ::RealSplitter < BasicSplitter
          def split(_packages)
            build_package
          end
        end

        # Custom package used to test setting package factory
        class ::CustomPackage
          def initialize(stock_location, order, splitters); end
        end
        allow(Spree::Config).to receive(:package_factory) { CustomPackage }

        expect(::RealSplitter.new(packer).split(nil).class).to eq CustomPackage
      end
    end
  end
end
