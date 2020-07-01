require 'spec_helper'

module Spree
  module Stock
    module Splitter
      describe Base do
        let(:packer) { build(:stock_packer) }

        it 'continues to splitter chain' do
          splitter1 = Base.new(packer)
          splitter2 = Base.new(packer, splitter1)
          packages = []

          splitter1.should_receive(:split).with(packages)
          splitter2.split(packages)
        end

        it 'builds package using package factory' do
          # Basic extension of Base splitter used to test build_package method
          class ::BasicSplitter < Base
            def split(packages)
              build_package
            end
          end

          # Custom package used to test setting package factory
          class ::CustomPackage
            def initialize(stock_location, order, splitters); end
          end
          allow(Spree::Config).to receive(:package_factory) { CustomPackage }

          expect(::BasicSplitter.new(packer).split(nil).class).to eq CustomPackage
        end
      end
    end
  end
end
