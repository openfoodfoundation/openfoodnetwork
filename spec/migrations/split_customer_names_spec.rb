# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20220105085730_migrate_customers_data'

describe MigrateCustomersData do
  let!(:customer1) {
    create(:customer, name: "Timmy Test", first_name: "", last_name: "", bill_address: nil)
  }
  let!(:customer2) {
    create(:customer,
           name: "Frank Lee Ridiculous", first_name: "", last_name: "",
           bill_address: create(:address, first_name: "Frank Lee", last_name: "Ridiculous"))
  }
  let!(:customer3) {
    create(:customer, name: "Shia Le Boeuf", first_name: "", last_name: "",
                      bill_address: create(:address, first_name: "Shia", last_name: "Le Boeuf"))
  }
  let!(:customer4) {
    create(:customer, name: "No Eyed Deer", first_name: "", last_name: "", bill_address: nil)
  }
  let!(:customer5) {
    create(:customer, name: "   Space     Invader   ", first_name: "", last_name: "",
                      bill_address: nil)
  }
  let!(:customer6) {
    create(:customer, name: "How   Many Names  Do You   Need?", first_name: "", last_name: "",
                      bill_address: nil)
  }
  let!(:customer7) {
    create(:customer,
           name: "Customer Name", first_name: "", last_name: "",
           bill_address: create(:address, first_name: "Different", last_name: "AddressName"))
  }

  it "migrates customer names" do
    subject.up

    [
      customer1, customer2, customer3, customer4,
      customer5, customer6, customer7,
    ].map(&:reload)

    expect([customer1.first_name, customer1.last_name]).to eq ["Timmy", "Test"]
    expect([customer2.first_name, customer2.last_name]).to eq ["Frank Lee", "Ridiculous"]
    expect([customer3.first_name, customer3.last_name]).to eq ["Shia", "Le Boeuf"]
    expect([customer4.first_name, customer4.last_name]).to eq ["No", "Eyed Deer"]
    expect([customer5.first_name, customer5.last_name]).to eq ["Space", "Invader"]
    expect([customer6.first_name, customer6.last_name]).to eq ["How", "Many Names Do You Need?"]
    expect([customer7.first_name, customer7.last_name]).to eq ["Customer", "Name"]
  end
end
