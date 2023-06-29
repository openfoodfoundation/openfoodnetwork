# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module UsersAndEnterprises
      describe Base do
        describe "query_result" do
          let!(:owners_and_enterprises) { double(:owners_and_enterprises) }
          let!(:managers_and_enterprises) { double(:managers_and_enterprises) }
          let!(:subject) { Base.new(nil, {}) }

          before do
            allow(subject).to receive(:owners_and_enterprises) { owners_and_enterprises }
            allow(subject).to receive(:managers_and_enterprises) { managers_and_enterprises }
          end

          it "should concatenate owner and manager queries" do
            expect(subject).to receive(:owners_and_enterprises).once
            expect(subject).to receive(:managers_and_enterprises).once
            expect(owners_and_enterprises).to receive(:concat)
              .with(managers_and_enterprises).and_return []
            expect(subject).to receive(:sort).with []
            subject.query_result
          end
        end

        describe "sorting results" do
          let!(:subject) { Base.new(nil, {}) }

          it "sorts by creation date" do
            uae_mock = [
              OpenStruct.new({ created_at: Date.new(2015, 1, 1), name: "aaa" }),
              OpenStruct.new({ created_at: Date.new(2015, 1, 2), name: "bbb" })
            ]
            expect(subject.sort(uae_mock)).to eq [uae_mock[1], uae_mock[0]]
          end

          it "sorts by creation date when nil date" do
            uae_mock = [
              OpenStruct.new({ created_at: nil, name: "aaa" }),
              OpenStruct.new({ created_at: Date.new(2015, 1, 2), name: "bbb" })
            ]
            expect(subject.sort(uae_mock)).to eq [uae_mock[1], uae_mock[0]]
          end

          it "then sorts by name" do
            uae_mock = [
              OpenStruct.new({ name: "aaa", relationship_type: "bbb", user_email: "bbb" }),
              OpenStruct.new({ name: "bbb", relationship_type: "aaa", user_email: "aaa" })
            ]
            expect(subject.sort(uae_mock)).to eq [uae_mock[0], uae_mock[1]]
          end

          it "then sorts by relationship type (reveresed)" do
            uae_mock = [
              OpenStruct.new({ name: "aaa", relationship_type: "bbb", user_email: "bbb" }),
              OpenStruct.new({ name: "aaa", relationship_type: "aaa", user_email: "aaa" }),
              OpenStruct.new({ name: "aaa", relationship_type: "bbb", user_email: "aaa" })
            ]
            expect(subject.sort(uae_mock)).to eq [uae_mock[2], uae_mock[0], uae_mock[1]]
          end

          it "then sorts by user_email" do
            uae_mock = [
              OpenStruct.new({ name: "aaa", relationship_type: "bbb", user_email: "aaa" }),
              OpenStruct.new({ name: "aaa", relationship_type: "aaa", user_email: "aaa" }),
              OpenStruct.new({ name: "aaa", relationship_type: "aaa", user_email: "bbb" })
            ]
            expect(subject.sort(uae_mock)).to eq [uae_mock[0], uae_mock[1], uae_mock[2]]
          end
        end

        describe "filtering results" do
          let!(:enterprise1) { create(:enterprise, owner: create(:user) ) }
          let!(:enterprise2) { create(:enterprise, owner: create(:user) ) }

          describe "for owners and enterprises" do
            describe "by enterprise id" do
              let!(:params) { { enterprise_id_in: [enterprise1.id.to_s] } }
              let!(:subject) { Base.new nil, params }

              it "excludes enterprises that are not explicitly requested" do
                results = subject.owners_and_enterprises.to_a.map{ |oae| oae["name"] }
                expect(results).to include enterprise1.name
                expect(results).to_not include enterprise2.name
              end
            end

            describe "by user id" do
              let!(:params) { { user_id_in: [enterprise1.owner.id.to_s] } }
              let!(:subject) { Base.new nil, params }

              it "excludes enterprises that are not explicitly requested" do
                results = subject.owners_and_enterprises.to_a.map{ |oae| oae["name"] }
                expect(results).to include enterprise1.name
                expect(results).to_not include enterprise2.name
              end
            end
          end

          describe "for managers and enterprises" do
            describe "by enterprise id" do
              let!(:params) { { enterprise_id_in: [enterprise1.id.to_s] } }
              let!(:subject) { Base.new nil, params }

              it "excludes enterprises that are not explicitly requested" do
                results = subject.managers_and_enterprises.to_a.map{ |mae| mae["name"] }
                expect(results).to include enterprise1.name
                expect(results).to_not include enterprise2.name
              end
            end

            describe "by user id" do
              let!(:manager1) { create(:user) }
              let!(:manager2) { create(:user) }
              let!(:params) { { user_id_in: [manager1.id.to_s] } }
              let!(:subject) { Base.new nil, params }

              before do
                enterprise1.enterprise_roles.build(user: manager1).save
                enterprise2.enterprise_roles.build(user: manager2).save
              end

              it "excludes enterprises whose managers are not explicitly requested" do
                results = subject.managers_and_enterprises.to_a.map{ |mae| mae["name"] }
                expect(results).to include enterprise1.name
                expect(results).to_not include enterprise2.name
              end
            end
          end
        end
      end
    end
  end
end
