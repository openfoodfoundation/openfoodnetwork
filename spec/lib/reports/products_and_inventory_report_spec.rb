# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module ProductsAndInventory
      describe Base do
        context "As a site admin" do
          let(:user) do
            user = create(:user)
            user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
            user
          end
          subject do
            Base.new user, {}
          end

          it "Should return headers" do
            expect(subject.table_headers).to eq([
                                                  "Supplier",
                                                  "Producer Suburb",
                                                  "Product",
                                                  "Product Properties",
                                                  "Taxons",
                                                  "Variant Value",
                                                  "Price",
                                                  "Group Buy Unit Quantity",
                                                  "Amount",
                                                  "SKU"
                                                ])
          end

          it "should build a table from a list of variants" do
            variant = double(:variant, sku: "sku",
                                       full_name: "Variant Name",
                                       count_on_hand: 10,
                                       price: 100)
            allow(variant).to receive_message_chain(:product, :supplier,
                                                    :name).and_return("Supplier")
            allow(variant).to receive_message_chain(:product, :supplier, :address,
                                                    :city).and_return("A city")
            allow(variant).to receive_message_chain(:product, :name).and_return("Product Name")
            allow(variant).to receive_message_chain(:product, :properties)
              .and_return [double(name: "property1"), double(name: "property2")]
            allow(variant).to receive_message_chain(:product, :primary_taxon).
              and_return double(name: "taxon1")
            allow(variant).to receive_message_chain(:product, :group_buy_unit_size).and_return(21)
            allow(subject).to receive(:query_result).and_return [variant]

            expect(subject.table_rows).to eq([[
                                               "Supplier",
                                               "A city",
                                               "Product Name",
                                               "property1, property2",
                                               "taxon1",
                                               "Variant Name",
                                               100,
                                               21,
                                               "",
                                               "sku"
                                             ]])
          end

          it "fetches variants for some params" do
            expect(subject).to receive(:child_variants).and_return ["children"]
            expect(subject).to receive(:filter).with(['children']).and_return ["filter_children"]
            expect(subject.query_result).to eq(["filter_children"])
          end
        end

        context "As an enterprise user" do
          let(:supplier) { create(:supplier_enterprise) }
          let(:enterprise_user) do
            user = create(:user)
            user.enterprise_roles.create(enterprise: supplier)
            user.spree_roles = []
            user.save!
            user
          end

          subject do
            Base.new enterprise_user, {}
          end

          describe "fetching child variants" do
            it "returns some variants" do
              product1 = create(:simple_product, supplier: supplier)
              variant1 = product1.variants.first
              variant2 = create(:variant, product: product1)

              expect(subject.child_variants).to match_array [variant1, variant2]
            end

            it "should only return variants managed by the user" do
              product1 = create(:simple_product, supplier: create(:supplier_enterprise))
              product2 = create(:simple_product, supplier: supplier)
              variant1 = product1.variants.first
              variant2 = product2.variants.first

              expect(subject.child_variants).to eq([variant2])
            end
          end

          describe "Filtering variants" do
            let(:variants) { Spree::Variant.where(nil).joins(:product) }

            describe "based on report type" do
              it "returns only variants on hand" do
                product1 = create(:simple_product, supplier: supplier, on_hand: 99)
                product2 = create(:simple_product, supplier: supplier, on_hand: 0)

                subject = Inventory.new enterprise_user
                expect(subject.filter(variants)).to eq([product1.variants.first])
              end
            end
            it "filters to a specific supplier" do
              supplier2 = create(:supplier_enterprise)
              product1 = create(:simple_product, supplier: supplier)
              product2 = create(:simple_product, supplier: supplier2)

              allow(subject).to receive(:params).and_return(supplier_id: supplier.id)
              expect(subject.filter(variants)).to eq([product1.variants.first])
            end
            it "filters to a specific distributor" do
              distributor = create(:distributor_enterprise)
              product1 = create(:simple_product, supplier: supplier)
              product2 = create(:simple_product, supplier: supplier)
              order_cycle = create(:simple_order_cycle, suppliers: [supplier],
                                                        distributors: [distributor],
                                                        variants: [product2.variants.first])

              allow(subject).to receive(:params).and_return(distributor_id: distributor.id)
              expect(subject.filter(variants)).to eq([product2.variants.first])
            end

            it "ignores variant overrides without filter" do
              distributor = create(:distributor_enterprise)
              product = create(:simple_product, supplier: supplier, price: 5)
              variant = product.variants.first
              order_cycle = create(:simple_order_cycle, suppliers: [supplier],
                                                        distributors: [distributor],
                                                        variants: [product.variants.first])
              create(:variant_override, hub: distributor, variant: variant, price: 2)

              result = subject.filter(variants)

              expect(result.first.price).to eq 5
            end

            it "considers variant overrides with distributor" do
              distributor = create(:distributor_enterprise)
              product = create(:simple_product, supplier: supplier, price: 5)
              variant = product.variants.first
              order_cycle = create(:simple_order_cycle, suppliers: [supplier],
                                                        distributors: [distributor],
                                                        variants: [product.variants.first])
              create(:variant_override, hub: distributor, variant: variant, price: 2)

              allow(subject).to receive(:params).and_return(distributor_id: distributor.id)
              result = subject.filter(variants)

              expect(result.first.price).to eq 2
            end

            it "filters to a specific order cycle" do
              distributor = create(:distributor_enterprise)
              product1 = create(:simple_product, supplier: supplier)
              product2 = create(:simple_product, supplier: supplier)
              order_cycle = create(:simple_order_cycle, suppliers: [supplier],
                                                        distributors: [distributor],
                                                        variants: [product1.variants.first])

              allow(subject).to receive(:params).and_return(order_cycle_id: order_cycle.id)
              expect(subject.filter(variants)).to eq([product1.variants.first])
            end

            it "should do all the filters at once" do
              # The following data ensures that this spec fails if any of the
              # filters fail. It's testing the filters are not impacting each other.
              distributor = create(:distributor_enterprise)
              other_distributor = create(:distributor_enterprise)
              other_supplier = create(:supplier_enterprise)
              not_filtered_variant = create(:simple_product, supplier: supplier).variants.first
              variant_filtered_by_order_cycle = create(:simple_product,
                                                       supplier: supplier).variants.first
              variant_filtered_by_distributor = create(:simple_product,
                                                       supplier: supplier).variants.first
              variant_filtered_by_supplier = create(:simple_product,
                                                    supplier: other_supplier).variants.first
              variant_filtered_by_stock = create(:simple_product, supplier: supplier,
                                                                  on_hand: 0).variants.first

              # This OC contains all products except the one that should be filtered
              # by order cycle. We create a separate OC further down to proof that
              # the product is passing all other filters.
              order_cycle = create(
                :simple_order_cycle,
                suppliers: [supplier, other_supplier],
                distributors: [distributor, other_distributor],
                variants: [
                  not_filtered_variant,
                  variant_filtered_by_distributor,
                  variant_filtered_by_supplier,
                  variant_filtered_by_stock
                ]
              )

              # Remove the distribution of one product for one distributor but still
              # sell it through the other distributor.
              order_cycle.exchanges.outgoing.find_by(receiver_id: distributor.id).
                exchange_variants.
                find_by(variant_id: variant_filtered_by_distributor).
                destroy

              # Make product available to be filtered later. See OC comment above.
              create(
                :simple_order_cycle,
                suppliers: [supplier],
                distributors: [distributor, other_distributor],
                variants: [
                  variant_filtered_by_order_cycle
                ]
              )

              subject = Inventory.new enterprise_user
              allow(subject).to receive(:params).and_return(
                order_cycle_id: order_cycle.id,
                supplier_id: supplier.id,
                distributor_id: distributor.id
              )

              expect(subject.filter(variants)).to match_array [not_filtered_variant]

              # And it integrates with the ordering of the `variants` method.
              expect(subject.query_result).to match_array [not_filtered_variant]
            end
          end

          describe "fetching SKU for a variant" do
            let(:variant) { create(:variant) }
            let(:product) { variant.product }

            before {
              product.update_attribute(:sku, "Product SKU")
              allow(subject).to receive(:query_result).and_return([variant])
            }

            context "when the variant has an SKU set" do
              before { variant.update_attribute(:sku, "Variant SKU") }
              it "returns it" do
                expect(subject.rows.first.sku).to eq "Variant SKU"
              end
            end

            context "when the variant has bo SKU set" do
              before { variant.update_attribute(:sku, "") }

              it "returns the product's SKU" do
                expect(subject.rows.first.sku).to eq "Product SKU"
              end
            end
          end
        end
      end

      describe AllProducts do
        let(:user) do
          user = create(:user)
          user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
          user
        end
        let(:report) do
          AllProducts.new user, { fields_to_hide: [] }
        end

        it "Should return headers" do
          expect(report.table_headers).to eq([
                                               "Supplier",
                                               "Producer Suburb",
                                               "Product",
                                               "Product Properties",
                                               "Taxons",
                                               "Variant Value",
                                               "Price",
                                               "Group Buy Unit Quantity",
                                               "Amount",
                                               "SKU",
                                               "On Demand?",
                                               "On Hand"
                                             ])
        end

        it "Should render 'On demand' when the product is available on demand" do
          product = create(:product)
          variant = product.variants.first
          variant.on_demand = true
          variant.on_hand = 15
          variant.save!

          first_row = report.table_rows.first
          on_demand_column = first_row[-2]
          on_hand_column = first_row[-1]

          expect(on_demand_column).to eq("Yes")
          expect(on_hand_column).to eq("On demand")
        end

        it "Should render the on hand count when the product is not available on demand" do
          product = create(:product)
          variant = product.variants.first
          variant.on_demand = false
          variant.on_hand = 22
          variant.save!

          first_row = report.table_rows.first
          on_demand_column = first_row[-2]
          on_hand_column = first_row[-1]

          expect(on_demand_column).to eq("No")
          expect(on_hand_column).to eq(22)
        end
      end
    end
  end
end
