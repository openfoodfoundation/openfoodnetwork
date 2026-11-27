# frozen_string_literal: true

shared_examples_for 'access granted' do
  it 'should allow read' do
    expect(subject).to be_able_to(:read, resource, token) if token
    expect(subject).to be_able_to(:read, resource) unless token
  end

  it 'should allow create' do
    expect(subject).to be_able_to(:create, resource, token) if token
    expect(subject).to be_able_to(:create, resource) unless token
  end

  it 'should allow update' do
    expect(subject).to be_able_to(:update, resource, token) if token
    expect(subject).to be_able_to(:update, resource) unless token
  end
end

shared_examples_for 'access denied' do
  it 'should not allow read' do
    expect(subject).not_to be_able_to(:read, resource)
  end

  it 'should not allow create' do
    expect(subject).not_to be_able_to(:create, resource)
  end

  it 'should not allow update' do
    expect(subject).not_to be_able_to(:update, resource)
  end
end

shared_examples_for 'admin granted' do
  it 'should allow admin' do
    expect(subject).to be_able_to(:admin, resource, token) if token
    expect(subject).to be_able_to(:admin, resource) unless token
  end
end

shared_examples_for 'admin denied' do
  it 'should not allow admin' do
    expect(subject).not_to be_able_to(:admin, resource)
  end
end

shared_examples_for 'index allowed' do
  it 'should allow index' do
    expect(subject).to be_able_to(:index, resource)
  end
end

shared_examples_for 'no index allowed' do
  it 'should not allow index' do
    expect(subject).not_to be_able_to(:index, resource)
  end
end

shared_examples_for 'create only' do
  it 'should allow create' do
    expect(subject).to be_able_to(:create, resource)
  end

  it 'should not allow read' do
    expect(subject).not_to be_able_to(:read, resource)
  end

  it 'should not allow update' do
    expect(subject).not_to be_able_to(:update, resource)
  end

  it 'should not allow index' do
    expect(subject).not_to be_able_to(:index, resource)
  end
end

shared_examples_for 'read only' do
  it 'should not allow create' do
    expect(subject).not_to be_able_to(:create, resource)
  end

  it 'should not allow update' do
    expect(subject).not_to be_able_to(:update, resource)
  end

  it 'should allow index' do
    expect(subject).to be_able_to(:index, resource)
  end
end

shared_examples_for 'update only' do
  it 'should not allow create' do
    expect(subject).not_to be_able_to(:create, resource)
  end

  it 'should not allow read' do
    expect(subject).not_to be_able_to(:read, resource)
  end

  it 'should allow update' do
    expect(subject).to be_able_to(:update, resource)
  end

  it 'should not allow index' do
    expect(subject).not_to be_able_to(:index, resource)
  end
end

shared_examples "allows access to Enterprise Fee Summary" do
  it "should be able to see link and read report" do
    is_expected.to have_link_to_enterprise_fee_summary
    is_expected.to have_direct_access_to_enterprise_fee_summary
  end

  def have_link_to_enterprise_fee_summary
    have_ability([:enterprise_fee_summary], for: :report)
  end

  def have_direct_access_to_enterprise_fee_summary
    have_ability([:show, :index], for: Admin::ReportsController)
  end
end

# Expects `user` to be an enterprise manager who is not a super admin.
shared_examples "can run every enterprise report" do
  let(:ability) { Spree::Ability.new(user) }

  it "can open the reports page" do
    expect(user).to have_ability([:admin, :index, :show, :create], for: Admin::ReportsController)
  end

  Spree::Ability::ENTERPRISE_REPORTS.each do |report_type|
    it "can run the #{report_type} report" do
      expect(ability).to be_able_to(report_type, :report)
    end
  end

  [:revenues_by_hub, :users_and_enterprises].each do |report_type|
    it "cannot run the super-admin-only #{report_type} report" do
      expect(ability).not_to be_able_to(report_type, :report)
    end
  end
end
