require 'rspec/rails'
require 'rspec/autorun'

# This spec file is one part of a two-part strategy to maintain data integrity. The first part
# is to proactively protect data integrity using database constraints (not null, foreign keys,
# etc) and ActiveRecord validations. As a backup to those two techniques, and particularly in
# the cases where it's not possible to model an integrity concern with database constraints,
# we can add a reactive integrity test here.

# These tests are run nightly and the results are emailed to the MAILTO address in
# config/schedule.rb if any failures occur.

# Ref: http://pluralsight.com/training/Courses/TableOfContents/database-your-friend


describe "data integrity" do
  it "has no deleted variants in order cycles" do
    # When a variant is soft deleted, it should be removed from all order cycles
    # via Spree::Product#delete or Spree::Variant#delete.
    evs = ExchangeVariant.joins(:variant).where('spree_variants.deleted_at IS NOT NULL')
    evs.count.should == 0
  end
end
