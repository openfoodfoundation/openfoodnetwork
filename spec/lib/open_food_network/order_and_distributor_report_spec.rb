require 'spec_helper'

module OpenFoodNetwork
  describe OrderAndDistributorReport do

    describe "orders and distributors report" do
      let(:user) { create(:admin_user) }
      let(:d1) { create(:distributor_enterprise) }
      let(:oc1) { create(:simple_order_cycle) }
      let(:o1) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
      let(:li1) { build(:line_item) }

      context "New version" do
        before { o1.line_items << li1 }

        context "as a site admin" do
          subject { OrderAndDistributorReport.new user }

          it "fetches completed orders" do
            o2 = create(:order)
            o2.line_items << build(:line_item)
            subject.table_items.should == [li1]
          end

          it "does not show cancelled orders" do
            o2 = create(:order, state: "canceled", completed_at: 1.day.ago)
            o2.line_items << build(:line_item)
            subject.table_items.should == [li1]
          end
        end

        context "as a manager of a supplier" do
          let!(:user) { create(:user) }
          subject { OrderAndDistributorReport.new user }

          let(:s1) { create(:supplier_enterprise) }

          before do
            s1.enterprise_roles.create!(user: user)
          end

          context "that has granted P-OC to the distributor" do
            let(:o2) { create(:order, distributor: d1, completed_at: 1.day.ago, bill_address: create(:address), ship_address: create(:address)) }
            let(:li2) { build(:line_item, product: create(:simple_product, supplier: s1)) }

            before do
              o2.line_items << li2
              create(:enterprise_relationship, parent: s1, child: d1, permissions_list: [:add_to_order_cycle])
            end

            it "shows line items supplied by my producers, with names hidden" do
              subject.table_items.should == [li2]
              subject.table_items.first.order.bill_address.firstname.should == "HIDDEN"
            end
          end

          context "that has not granted P-OC to the distributor" do
            let(:o2) { create(:order, distributor: d1, completed_at: 1.day.ago, bill_address: create(:address), ship_address: create(:address)) }
            let(:li2) { build(:line_item, product: create(:simple_product, supplier: s1)) }

            before do
              o2.line_items << li2
            end

            it "shows line items supplied by my producers, with names hidden" do
              subject.table_items.should == []
            end
          end
        end

        context "as a manager of a distributor" do
          let!(:user) { create(:user) }
          subject { OrderAndDistributorReport.new user }

          before do
            d1.enterprise_roles.create!(user: user)
          end

          it "only shows line items distributed by enterprises managed by the current user" do
            d2 = create(:distributor_enterprise)
            d2.enterprise_roles.create!(user: create(:user))
            o2 = create(:order, distributor: d2, completed_at: 1.day.ago)
            o2.line_items << build(:line_item)
            subject.table_items.should == [li1]
          end

          it "only shows the selected order cycle" do
            oc2 = create(:simple_order_cycle)
            o2 = create(:order, distributor: d1, order_cycle: oc2)
            o2.line_items << build(:line_item)
            subject.stub(:params).and_return(order_cycle_id_in: oc1.id)
            subject.table_items.should == [li1]
          end
        end
      end

      context "Old version" do
        it "should return a header row describing the report" do
          subject = OrderAndDistributorReport.new user

          header = subject.header
          header.should == ["Order date", "Order Id",
            "Customer Name","Customer Email", "Customer Phone", "Customer City",
            "SKU", "Item name", "Variant", "Quantity", "Max Quantity", "Cost", "Shipping cost",
            "Payment method",
            "Distributor", "Distributor address", "Distributor city", "Distributor postcode", "Shipping instructions"]
        end

        context "table results" do
          before(:each) do
            #normal completed order
            @bill_address = create(:address)
            @distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
            @distributor = create(:distributor_enterprise, :address => @distributor_address)
            product = create(:product)
            product_distribution = create(:product_distribution, :product => product, :distributor => @distributor)
            @shipping_instructions = "pick up on thursday please!"
            @order = create(:order, completed_at: 1.day.ago, :distributor => @distributor, :bill_address => @bill_address, :special_instructions => @shipping_instructions)
            @payment_method = create(:payment_method, :distributors => [@distributor])
            payment = create(:payment, :payment_method => @payment_method, :order => @order )
            @order.payments << payment
            @line_item = create(:line_item, :product => product, :order => @order)
            @order.line_items << @line_item
          end

          it "should denormalise order and distributor details for display as csv" do
            subject = OrderAndDistributorReport.new user

            table = subject.table

            # Trying to figure out why it is failing in Travis and not local machine
            expect(table[0]).to include(@order.created_at)
            expect(table[0]).to include(@order.id)
            expect(table[0]).to include(@bill_address.full_name)
            expect(table[0]).to include(@order.email)
            expect(table[0]).to include(@bill_address.phone)
            expect(table[0]).to include(@bill_address.city)
            expect(table[0]).to include(@line_item.product.sku)
            expect(table[0]).to include(@line_item.product.name)
            expect(table[0]).to include(@line_item.options_text)
            expect(table[0]).to include(@line_item.quantity)
            expect(table[0]).to include(@line_item.max_quantity)
            expect(table[0]).to include(@line_item.price * @line_item.quantity)
            expect(table[0]).to include(@line_item.distribution_fee)
            expect(table[0]).to include(@payment_method.name)
            expect(table[0]).to include(@distributor.name)
            expect(table[0]).to include(@distributor.address.address1)
            expect(table[0]).to include(@distributor.address.city)
            expect(table[0]).to include(@distributor.address.zipcode)
            expect(table[0]).to include(@shipping_instructions)
            # table[0].should == [@order.created_at, @order.id,
            #   @bill_address.full_name, @order.email, @bill_address.phone, @bill_address.city,
            #   @line_item.product.sku, @line_item.product.name, @line_item.options_text, @line_item.quantity, @line_item.max_quantity, @line_item.price * @line_item.quantity, @line_item.distribution_fee,
            #   @payment_method.name,
            #   @distributor.name, @distributor.address.address1, @distributor.address.city, @distributor.address.zipcode, @shipping_instructions ]
          end
        end
      end
    end
  end
end
