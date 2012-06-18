require 'spec_helper'

describe Spree::Product do

  describe "associations" do
    it { should belong_to(:supplier) }
    it { should have_and_belong_to_many(:distributors) }
  end

end
