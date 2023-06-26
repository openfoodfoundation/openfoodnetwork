# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/order_cycle_permissions'

module OpenFoodNetwork
  describe OrderCyclePermissions do
    let(:coordinator) { create(:distributor_enterprise) }
    let(:hub) { create(:distributor_enterprise) }
    let(:producer) { create(:supplier_enterprise) }
    let(:user) { double(:user) }
    let(:oc) { create(:simple_order_cycle, coordinator: coordinator) }
    let(:permissions) { OrderCyclePermissions.new(user, oc) }

    describe "finding enterprises that can be viewed in the order cycle interface" do
      context "when permissions are initialized without an order_cycle" do
        let(:permissions) { OrderCyclePermissions.new(user, nil) }

        before do
          allow(permissions).to receive(:managed_enterprises) {
                                  Enterprise.where(id: [coordinator])
                                }
        end

        it "returns an empty scope" do
          expect(permissions.visible_enterprises).to be_empty
        end
      end

      context "as a manager of the coordinator" do
        before do
          allow(permissions).to receive(:managed_enterprises) {
                                  Enterprise.where(id: [coordinator])
                                }
        end

        it "returns the coordinator itself" do
          expect(permissions.visible_enterprises).to include coordinator
        end

        context "where P-OC has been granted to the coordinator by other enterprises" do
          before do
            create(:enterprise_relationship, parent: hub, child: coordinator,
                                             permissions_list: [:add_to_order_cycle])
          end

          context "where the coordinator sells any" do
            it "returns enterprises which have granted P-OC to the coordinator" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to include hub
              expect(enterprises).to_not include producer
            end
          end

          context "where the coordinator sells 'own'" do
            before { allow(coordinator).to receive(:sells) { 'own' } }
            it "returns just the coordinator" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to_not include hub, producer
            end
          end
        end

        context "where P-OC has not been granted to the coordinator by other enterprises" do
          context "where the other enterprise are already in the order cycle" do
            let!(:ex_incoming) {
              create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                                incoming: true)
            }
            let!(:ex_outgoing) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            context "where the coordinator sells any" do
              it "returns enterprises which have granted P-OC to the coordinator" do
                enterprises = permissions.visible_enterprises
                expect(enterprises).to include hub, producer
              end
            end

            context "where the coordinator sells 'own'" do
              before { allow(coordinator).to receive(:sells) { 'own' } }
              it "returns just the coordinator" do
                enterprises = permissions.visible_enterprises
                expect(enterprises).to_not include hub, producer
              end
            end
          end

          context "where the other enterprises are not in the order cycle" do
            it "returns just the coordinator" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to_not include hub, producer
            end
          end
        end
      end

      context "as a manager of a hub" do
        before do
          allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub]) }
        end

        context "that has granted P-OC to the coordinator" do
          before do
            create(:enterprise_relationship, parent: hub, child: coordinator,
                                             permissions_list: [:add_to_order_cycle])
          end

          context "where my hub is in the order cycle" do
            let!(:ex_outgoing) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            it "returns my hub" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to include hub
              expect(enterprises).to_not include producer, coordinator
            end

            context "and has been granted P-OC by a producer" do
              before do
                create(:enterprise_relationship, parent: producer, child: hub,
                                                 permissions_list: [:add_to_order_cycle])
              end

              context "where the producer is in the order cycle" do
                let!(:ex_incoming) {
                  create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                                    incoming: true)
                }

                it "returns the producer" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to include producer, hub
                end
              end

              context "where the producer is not in the order cycle" do
                # No incoming exchange

                it "does not return the producer" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to_not include producer
                end
              end
            end

            context "and has granted P-OC to a producer" do
              before do
                create(:enterprise_relationship, parent: hub, child: producer,
                                                 permissions_list: [:add_to_order_cycle])
              end

              context "where the producer is in the order cycle" do
                let!(:ex_incoming) {
                  create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                                    incoming: true)
                }

                it "returns the producer" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to include producer, hub
                end
              end

              context "where the producer is not in the order cycle" do
                # No incoming exchange

                it "does not return the producer" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to_not include producer
                end
              end
            end
          end

          context "where my hub is not in the order cycle" do
            # No outgoing exchange for my hub

            it "does not return my hub" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to_not include hub, producer, coordinator
            end
          end
        end

        context "that has not granted P-OC to the coordinator" do
          it "does not return my hub" do
            enterprises = permissions.visible_enterprises
            expect(enterprises).to_not include hub, producer, coordinator
          end

          context "but is already in the order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            it "returns my hub" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to include hub
              expect(enterprises).to_not include producer, coordinator
            end

            context "and distributes variants distributed by an unmanaged & unpermitted producer" do
              before {
                ex.variants << create(:variant, product: create(:product, supplier: producer))
              }

              # TODO: update this when we are confident about P-OCs
              it "returns that producer as well" do
                enterprises = permissions.visible_enterprises
                expect(enterprises).to include producer, hub
                expect(enterprises).to_not include coordinator
              end
            end
          end
        end
      end

      context "as a manager of a producer" do
        before do
          allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [producer]) }
        end

        context "which has granted P-OC to the coordinator" do
          before do
            create(:enterprise_relationship, parent: producer, child: coordinator,
                                             permissions_list: [:add_to_order_cycle])
          end

          context "where my producer is in the order cycle" do
            let!(:ex_incoming) {
              create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                                incoming: true)
            }

            it "returns my producer" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to include producer
              expect(enterprises).to_not include hub, coordinator
            end

            context "and has been granted P-OC by a hub" do
              before do
                create(:enterprise_relationship, parent: hub, child: producer,
                                                 permissions_list: [:add_to_order_cycle])
              end

              context "where the hub is also in the order cycle" do
                let!(:ex_outgoing) {
                  create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                    incoming: false)
                }

                it "returns the hub as well" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to include producer, hub
                  expect(enterprises).to_not include coordinator
                end
              end

              context "where the hub is not in the order cycle" do
                # No outgoing exchange

                it "does not return the hub" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to_not include hub
                end
              end
            end

            context "and has granted P-OC to a hub" do
              before do
                create(:enterprise_relationship, parent: producer, child: hub,
                                                 permissions_list: [:add_to_order_cycle])
              end

              context "where the hub is also in the order cycle" do
                let!(:ex_outgoing) {
                  create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                    incoming: false)
                }

                it "returns the hub as well" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to include producer, hub
                  expect(enterprises).to_not include coordinator
                end
              end

              context "where the hub is not in the order cycle" do
                # No outgoing exchange

                it "does not return the hub" do
                  enterprises = permissions.visible_enterprises
                  expect(enterprises).to_not include hub
                end
              end
            end
          end

          context "where my producer is not in the order cycle" do
            # No incoming exchange for producer

            it "does not return my producer" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to_not include hub, producer, coordinator
            end
          end
        end

        context "which has not granted P-OC to the coordinator" do
          it "does not return my producer" do
            enterprises = permissions.visible_enterprises
            expect(enterprises).to_not include producer
          end

          context "but is already in the order cycle" do
            let!(:ex_incoming) {
              create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                                incoming: true)
            }

            # TODO: update this when we are confident about P-OCs
            it "returns my producer" do
              enterprises = permissions.visible_enterprises
              expect(enterprises).to include producer
              expect(enterprises).to_not include hub, coordinator
            end

            context "and has variants distributed by an outgoing hub" do
              let!(:ex_outgoing) {
                create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                  incoming: false)
              }
              before {
                ex_outgoing.variants << create(:variant,
                                               product: create(:product, supplier: producer))
              }

              # TODO: update this when we are confident about P-OCs
              it "returns that hub as well" do
                enterprises = permissions.visible_enterprises
                expect(enterprises).to include producer, hub
                expect(enterprises).to_not include coordinator
              end
            end
          end
        end
      end
    end

    describe "finding exchanges of an order cycle that an admin can manage" do
      describe "as the manager of the coordinator" do
        let!(:ex_in) {
          create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                            incoming: true)
        }
        let!(:ex_out) {
          create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub, incoming: false)
        }

        before do
          allow(permissions).to receive(:managed_enterprises) {
                                  Enterprise.where(id: [coordinator])
                                }
        end

        it "returns all exchanges in the order cycle, regardless of hubE permissions" do
          expect(permissions.visible_exchanges).to include ex_in, ex_out
        end
      end

      describe "as the manager of a hub" do
        let!(:ex_in) {
          create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                            incoming: true)
        }

        before do
          allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub]) }
        end

        context "where my hub is in the order cycle" do
          let!(:ex_out) {
            create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub, incoming: false)
          }

          it "returns my hub's outgoing exchange" do
            expect(permissions.visible_exchanges).to eq([ex_out])
          end

          context "where my hub has been granted P-OC by an incoming producer" do
            before do
              create(:enterprise_relationship, parent: producer, child: hub,
                                               permissions_list: [:add_to_order_cycle])
            end

            it "returns the producer's incoming exchange" do
              expect(permissions.visible_exchanges).to include ex_in
            end
          end

          context "where my hub has not been granted P-OC by an incoming producer" do
            it "returns the producers's incoming exchange, and my own outhoing exchange" do
              expect(permissions.visible_exchanges).not_to include ex_in
            end
          end
        end

        context "where my hub isn't in the order cycle" do
          it "does not return the producer's incoming exchanges" do
            expect(permissions.visible_exchanges).to eq([])
          end
        end

        # TODO: this is testing legacy behaviour for backwards compatability,
        # remove when behaviour no longer required
        describe "legacy compatability" do
          context "where my hub's outgoing exchange contains variants of a producer " \
                  "I don't manage and has not given my hub P-OC" do
            let!(:product) { create(:product, supplier: producer) }
            let!(:variant) { create(:variant, product: product) }
            let!(:ex_out) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub, incoming: true)
            }
            before { ex_out.variants << variant }

            it "returns incoming exchanges supplying the variants in my outgoing exchange" do
              expect(permissions.visible_exchanges).to include ex_out
            end
          end
        end
      end

      describe "as the manager of a producer" do
        let!(:ex_out) {
          create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub, incoming: false)
        }

        before do
          allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [producer]) }
        end

        context "where my producer supplies to the order cycle" do
          let!(:ex_in) {
            create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                              incoming: true)
          }

          it "returns my producer's incoming exchange" do
            expect(permissions.visible_exchanges).to eq([ex_in])
          end

          context "my producer has granted P-OC to an outgoing hub" do
            before do
              create(:enterprise_relationship, parent: producer, child: hub,
                                               permissions_list: [:add_to_order_cycle])
            end

            it "returns the hub's outgoing exchange" do
              expect(permissions.visible_exchanges).to include ex_out
            end
          end

          context "my producer has not granted P-OC to an outgoing hub" do
            it "does not return the hub's outgoing exchange" do
              expect(permissions.visible_exchanges).not_to include ex_out
            end
          end
        end

        context "where my producer doesn't supply the order cycle" do
          it "does not return the hub's outgoing exchanges" do
            expect(permissions.visible_exchanges).to eq([])
          end
        end

        # TODO: this is testing legacy behaviour for backwards compatability,
        # remove when behaviour no longer required
        describe "legacy compatability" do
          context "where an outgoing exchange contains variants of a producer I manage" do
            let!(:product) { create(:product, supplier: producer) }
            let!(:variant) { create(:variant, product: product) }
            before { ex_out.variants << variant }

            context "where my producer supplies to the order cycle" do
              let!(:ex_in) {
                create(:exchange, order_cycle: oc, sender: producer, receiver: coordinator,
                                  incoming: true)
              }

              it "returns the outgoing exchange" do
                expect(permissions.visible_exchanges).to include ex_out
              end
            end

            context "where my producer doesn't supply to the order cycle" do
              it "does not return the outgoing exchange" do
                expect(permissions.visible_exchanges).not_to include ex_out
              end
            end
          end
        end
      end
    end

    describe "finding the variants within a hypothetical exchange " \
             "between two enterprises which are visible to a user" do
      let!(:producer1) { create(:supplier_enterprise) }
      let!(:producer2) { create(:supplier_enterprise) }
      let!(:v1) { create(:variant, product: create(:simple_product, supplier: producer1)) }
      let!(:v2) { create(:variant, product: create(:simple_product, supplier: producer2)) }

      describe "incoming exchanges" do
        context "as a manager of the coordinator" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [coordinator])
                                  }
          end

          it "returns all variants belonging to the sending producer" do
            visible = permissions.visible_variants_for_incoming_exchanges_from(producer1)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as a manager of the producer" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [producer1])
                                  }
          end

          it "returns all variants belonging to the sending producer" do
            visible = permissions.visible_variants_for_incoming_exchanges_from(producer1)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as a manager of a hub which has been granted P-OC by the producer" do
          before do
            allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub]) }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          context "where the hub is in the order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            it "returns variants produced by that producer only" do
              visible = permissions.visible_variants_for_incoming_exchanges_from(producer1)
              expect(visible).to include v1
              expect(visible).to_not include v2
            end
          end

          context "where the hub is not in the order cycle" do
            # No outgoing exchange

            it "does not return variants produced by that producer" do
              visible = permissions.visible_variants_for_incoming_exchanges_from(producer1)
              expect(visible).to_not include v1, v2
            end
          end
        end
      end

      describe "outgoing exchanges" do
        context "as a manager of the coordinator" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [coordinator])
                                  }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "returns all variants of any producer which has granted the outgoing hub P-OC" do
            visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end

          context "where the coordinator produces products" do
            let!(:v3) { create(:variant, product: create(:simple_product, supplier: coordinator)) }

            it "returns any variants produced by the coordinator itself for exchanges w/ 'self'" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(coordinator)
              expect(visible).to include v3
              expect(visible).to_not include v1, v2
            end

            it "does not return coordinator's variants for exchanges with other hubs, " \
               "when permission has not been granted" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1
              expect(visible).to_not include v2, v3
            end
          end

          # TODO: for backwards compatability, remove later
          context "when an exchange exists between the coordinator " \
                  "and the hub within this order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            # producer2 produces v2 and has not granted P-OC to hub (or coordinator for that matter)
            before { ex.variants << v2 }

            it "returns those variants that are in the exchange" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1, v2
            end
          end
        end

        context "as manager of an outgoing hub" do
          before do
            allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub]) }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "returns all variants of any producer which has granted the outgoing hub P-OC" do
            visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end

          context "where the hub produces products" do
            # NOTE: No relationship to self required
            let!(:v3) { create(:variant, product: create(:simple_product, supplier: hub)) }

            it "returns any variants produced by the hub" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v3
            end
          end

          # TODO: for backwards compatability, remove later
          context "when an exchange exists between the coordinator " \
                  "and the hub within this order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            # producer2 produces v2 and has not granted P-OC to hub
            before { ex.variants << v2 }

            it "returns those variants that are in the exchange" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1, v2
            end
          end
        end

        context "as the manager of a producer which has granted P-OC to an outgoing hub" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [producer1])
                                  }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          context "where my producer is in the order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: producer1, receiver: coordinator,
                                incoming: true)
            }

            it "returns all of my produced variants" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1
              expect(visible).to_not include v2
            end
          end

          context "where my producer isn't in the order cycle" do
            # No incoming exchange

            it "does not return my variants" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to_not include v1, v2
            end
          end
        end

        context "as the manager of a producer which has not granted P-OC to an outgoing hub" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [producer2])
                                  }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "returns an empty array" do
            expect(permissions.visible_variants_for_outgoing_exchanges_to(hub)).to eq []
          end

          # TODO: for backwards compatability, remove later
          context "but which has variants already in the exchange" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }
            # This one won't be in the exchange, and so shouldn't be visible
            let!(:v3) { create(:variant, product: create(:simple_product, supplier: producer2)) }

            before { ex.variants << v2 }

            it "returns those variants that are in the exchange" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to_not include v1, v3
              expect(visible).to include v2
            end
          end
        end
      end
    end

    describe "finding the variants within a hypothetical exchange " \
             "between two enterprises which are editable by a user" do
      let!(:producer1) { create(:supplier_enterprise) }
      let!(:producer2) { create(:supplier_enterprise) }
      let!(:v1) { create(:variant, product: create(:simple_product, supplier: producer1)) }
      let!(:v2) { create(:variant, product: create(:simple_product, supplier: producer2)) }

      describe "incoming exchanges" do
        context "as a manager of the coordinator" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [coordinator])
                                  }
          end

          it "returns all variants belonging to the sending producer" do
            visible = permissions.editable_variants_for_incoming_exchanges_from(producer1)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as a manager of the producer" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [producer1])
                                  }
          end

          it "returns all variants belonging to the sending producer" do
            visible = permissions.editable_variants_for_incoming_exchanges_from(producer1)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end
        end

        context "as a manager of a hub which has been granted P-OC by the producer" do
          before do
            allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub]) }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "does not return variants produced by that producer" do
            visible = permissions.editable_variants_for_incoming_exchanges_from(producer1)
            expect(visible).to_not include v1, v2
          end
        end
      end

      describe "outgoing exchanges" do
        context "as a manager of the coordinator" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [coordinator])
                                  }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "returns all variants of any producer which has granted the outgoing hub P-OC" do
            visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end

          context "where the coordinator produces products" do
            let!(:v3) { create(:variant, product: create(:simple_product, supplier: coordinator)) }

            it "returns any variants produced by the coordinator itself for exchanges w/ 'self'" do
              visible = permissions.editable_variants_for_outgoing_exchanges_to(coordinator)
              expect(visible).to include v3
              expect(visible).to_not include v1, v2
            end

            it "does not return coordinator's variants for exchanges with other hubs, " \
               "when permission has not been granted" do
              visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1
              expect(visible).to_not include v2, v3
            end
          end

          # TODO: for backwards compatability, remove later
          context "when an exchange exists between the coordinator and the hub within this OC" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            # producer2 produces v2 and has not granted P-OC to hub (or coordinator for that matter)
            before { ex.variants << v2 }

            it "returns those variants that are in the exchange" do
              visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1, v2
            end
          end
        end

        context "as manager of an outgoing hub" do
          before do
            allow(permissions).to receive(:managed_enterprises) { Enterprise.where(id: [hub]) }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "returns all variants of any producer which has granted the outgoing hub P-OC" do
            visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
            expect(visible).to include v1
            expect(visible).to_not include v2
          end

          context "where the hub produces products" do
            # NOTE: No relationship to self required
            let!(:v3) { create(:variant, product: create(:simple_product, supplier: hub)) }

            it "returns any variants produced by the hub" do
              visible = permissions.visible_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v3
            end
          end

          # TODO: for backwards compatability, remove later
          context "when an exchange exists between the coordinator " \
                  "and the hub within this order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }

            # producer2 produces v2 and has not granted P-OC to hub
            before { ex.variants << v2 }

            it "returns those variants that are in the exchange" do
              visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to include v1, v2
            end
          end
        end

        context "as the manager of a producer which has granted P-OC to an outgoing hub" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [producer1])
                                  }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          context "where my producer is in the order cycle" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: producer1, receiver: coordinator,
                                incoming: true)
            }

            context "where the outgoing hub has granted P-OC to my producer" do
              before do
                create(:enterprise_relationship, parent: hub, child: producer1,
                                                 permissions_list: [:add_to_order_cycle])
              end

              it "returns all of my produced variants" do
                visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
                expect(visible).to include v1
                expect(visible).to_not include v2
              end
            end

            context "where the outgoing hub has not granted P-OC to my producer" do
              # No permission granted

              it "does not return my variants" do
                visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
                expect(visible).to_not include v1, v2
              end
            end
          end

          context "where my producer isn't in the order cycle" do
            # No incoming exchange

            it "does not return my variants" do
              visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to_not include v1, v2
            end
          end
        end

        context "as the manager of a producer which has not granted P-OC to an outgoing hub" do
          before do
            allow(permissions).to receive(:managed_enterprises) {
                                    Enterprise.where(id: [producer2])
                                  }
            create(:enterprise_relationship, parent: producer1, child: hub,
                                             permissions_list: [:add_to_order_cycle])
          end

          it "returns an empty array" do
            expect(permissions.editable_variants_for_outgoing_exchanges_to(hub)).to eq []
          end

          # TODO: for backwards compatability, remove later
          context "but which has variants already in the exchange" do
            let!(:ex) {
              create(:exchange, order_cycle: oc, sender: coordinator, receiver: hub,
                                incoming: false)
            }
            # This one won't be in the exchange, and so shouldn't be visible
            let!(:v3) { create(:variant, product: create(:simple_product, supplier: producer2)) }

            before { ex.variants << v2 }

            it "does not return my variants" do
              visible = permissions.editable_variants_for_outgoing_exchanges_to(hub)
              expect(visible).to_not include v1, v2, v3
            end
          end
        end
      end
    end
  end
end
