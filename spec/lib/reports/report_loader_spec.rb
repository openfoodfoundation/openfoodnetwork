# frozen_string_literal: true

module Reporting
  module Reports
    module Bananas
      const_set "Base", Class.new
      const_set "Green", Class.new
      const_set "Yellow", Class.new
    end

    module Orange
      const_set "OrangeReport", Class.new
    end
  end
end

RSpec.describe Reporting::ReportLoader do
  let(:service) { Reporting::ReportLoader.new(*arguments) }
  let(:report_base_class) { Reporting::Reports::Bananas::Base }
  let(:report_subtypes) { ["green", "yellow"] }

  describe "#report_class" do
    describe "given report type and subtype" do
      let(:arguments) { ["bananas", "yellow"] }

      it "returns a report class when given type and subtype" do
        expect(service.report_class).to eq Reporting::Reports::Bananas::Yellow
      end
    end

    describe "given report type only" do
      context "when the report has no subtypes" do
        let(:arguments) { ["bananas"] }

        it "returns base class" do
          expect(service.report_class).to eq Reporting::Reports::Bananas::Base
        end
      end

      context "when the subtype is not implemented, fallback to base" do
        let(:arguments) { ["bananas", "not_existing"] }

        it "returns base class" do
          expect(service.report_class).to eq Reporting::Reports::Bananas::Base
        end
      end

      context "given a report type that does not exist" do
        let(:arguments) { ["apples"] }

        it "raises an error" do
          expect{ service.report_class }.to raise_error(Reporting::Errors::ReportNotFound)
        end
      end
    end
  end
end
