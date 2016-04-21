require 'spec_helper'

describe TagRule, type: :model do
  let!(:tag_rule) { create(:tag_rule) }

  describe "validations" do
    it "requires a enterprise" do
      expect(tag_rule).to validate_presence_of :enterprise
    end
  end

  describe 'setting the context' do
    let(:subject) { double(:subject) }
    let(:context) { { subject: subject, some_other_property: "yay"} }

    it "raises an error when context is nil" do
      expect{ tag_rule.set_context(nil) }.to raise_error "Context for tag rule cannot be nil"
    end

    it "raises an error when subject is nil" do
      expect{ tag_rule.set_context({}) }.to raise_error "Subject for tag rule cannot be nil"
    end

    it "stores the subject and context provided as instance variables on the model" do
      tag_rule.set_context(context)
      expect(tag_rule.subject).to eq subject
      expect(tag_rule.context).to eq context
      expect(tag_rule.instance_variable_get(:@subject)).to eq subject
      expect(tag_rule.instance_variable_get(:@context)).to eq context
    end
  end

  describe "determining relevance based on subject and context" do
    context "when the subject is nil" do
      it "returns false" do
        expect(tag_rule.send(:relevant?)).to be false
      end
    end

    context "when the subject is not nil" do
      let(:subject) { double(:subject) }

      before do
        tag_rule.set_context({subject: subject})
        allow(tag_rule).to receive(:customer_tags_match?) { :customer_tags_match_result }
        allow(tag_rule).to receive(:subject_class) { Spree::Order}
      end


      context "when the subject class matches tag_rule#subject_class" do
        before do
          allow(subject).to receive(:class) { Spree::Order }
        end

        context "when the rule does not repond to #additional_requirements_met?" do
          before { allow(tag_rule).to receive(:respond_to?).with(:additional_requirements_met?, true) { false } }

          it "returns true" do
            expect(tag_rule.send(:relevant?)).to be true
          end
        end

        context "when the rule reponds to #additional_requirements_met?" do
          before { allow(tag_rule).to receive(:respond_to?).with(:additional_requirements_met?, true) { true } }

          context "and #additional_requirements_met? returns a truthy value" do
            before { allow(tag_rule).to receive(:additional_requirements_met?) { "smeg" } }

            it "returns true immediately" do
              expect(tag_rule.send(:relevant?)).to be true
            end
          end

          context "and #additional_requirements_met? returns true" do
            before { allow(tag_rule).to receive(:additional_requirements_met?) { true } }

            it "returns true immediately" do
              expect(tag_rule.send(:relevant?)).to be true
            end
          end

          context "and #additional_requirements_met? returns false" do
            before { allow(tag_rule).to receive(:additional_requirements_met?) { false } }

            it "returns false immediately" do
              expect(tag_rule.send(:relevant?)).to be false
            end
          end
        end
      end

      context "when the subject class does not match tag_rule#subject_class" do
        before do
          allow(subject).to receive(:class) { Spree::LineItem }
        end

        it "returns false immediately" do
          expect(tag_rule.send(:relevant?)).to be false
          expect(tag_rule).to_not have_received :customer_tags_match?
        end
      end
    end

    describe "determining whether specified customer tags match the given context" do
      context "when the context has no customer tags specified" do
        let(:context) { { subject: double(:something), not_tags: double(:not_tags) } }

        before { tag_rule.set_context(context) }

        it "returns false" do
          expect(tag_rule.send(:customer_tags_match?)).to be false
        end
      end

      context "when the context has customer tags specified" do
        let(:context) { { subject: double(:something), customer_tags: ["member","local","volunteer"] } }

        before { tag_rule.set_context(context) }

        context "when the rule has no preferred customer tags specified" do
          before do
            allow(tag_rule).to receive(:preferred_customer_tags) { "" }
          end

          it "returns false" do
            expect(tag_rule.send(:customer_tags_match?)).to be false
          end
        end

        context "when the rule has preferred customer tags specified that match ANY of the customer tags" do
          before do
            allow(tag_rule).to receive(:preferred_customer_tags) { "wholesale,some_tag,member" }
          end

          it "returns false" do
            expect(tag_rule.send(:customer_tags_match?)).to be true
          end
        end

        context "when the rule has preferred customer tags specified that match NONE of the customer tags" do
          before do
            allow(tag_rule).to receive(:preferred_customer_tags) { "wholesale,some_tag,some_other_tag" }
          end

          it "returns false" do
            expect(tag_rule.send(:customer_tags_match?)).to be false
          end
        end
      end
    end

    describe "applying a tag rule to a subject" do
      before { allow(tag_rule).to receive(:apply!) }

      context "when the rule is deemed to be relevant" do
        before { allow(tag_rule).to receive(:relevant?) { true } }

        context "and customer_tags_match? returns true" do
          before { expect(tag_rule).to receive(:customer_tags_match?) { true } }

          it "applies the rule" do
            tag_rule.apply
            expect(tag_rule).to have_received(:apply!)
          end
        end

        context "when customer_tags_match? returns false" do
          before { expect(tag_rule).to receive(:customer_tags_match?) { false } }
          before { allow(tag_rule).to receive(:apply_default!) }

          context "and the rule responds to #apply_default!" do
            before { allow(tag_rule).to receive(:respond_to?).with(:apply_default!, true) { true } }

            it "applies the default action" do
              tag_rule.apply
              expect(tag_rule).to_not have_received(:apply!)
              expect(tag_rule).to have_received(:apply_default!)
            end
          end

          context "and the rule does not respond to #apply_default!" do
            before { allow(tag_rule).to receive(:respond_to?).with(:apply_default!, true) { false } }

            it "does not apply the rule or the default action" do
              tag_rule.apply
              expect(tag_rule).to_not have_received(:apply!)
              expect(tag_rule).to_not have_received(:apply_default!)
            end
          end
        end
      end

      context "when the rule is deemed not to be relevant" do
        before { allow(tag_rule).to receive(:relevant?) { false } }

        it "does not apply the rule" do
          tag_rule.apply
          expect(tag_rule).to_not have_received(:apply!)
        end
      end
    end
  end
end
