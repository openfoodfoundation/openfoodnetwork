require 'spec_helper'

describe EnterpriseFee do
  describe "associations" do
    it { should belong_to(:enterprise) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end
end
