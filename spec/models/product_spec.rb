require 'spec_helper'

describe Spree::Product do

  describe "associations" do
    it { should belong_to(:supplier) }
  end

end
