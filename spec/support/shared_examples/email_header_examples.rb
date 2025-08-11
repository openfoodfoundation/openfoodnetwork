# frozen_string_literal: true

RSpec.shared_examples 'email with inactive white labelling' do |mail|
  it 'always displays the OFN header with logo' do
    expect(public_send(mail).body).to include(ContentConfig.url_for(:logo))
  end
end

RSpec.shared_examples 'non-customer facing email with active white labelling' do |mail|
  context 'when hide OFN navigation is enabled for the distributor of the order' do
    before do
      order.distributor.hide_ofn_navigation = true
    end

    it 'still displays the OFN header with logo' do
      expect(public_send(mail).body).to include(ContentConfig.url_for(:logo))
    end
  end
end

RSpec.shared_examples 'customer facing email with active white labelling' do |mail|
  context 'when hide OFN navigation is enabled for the distributor of the order' do
    before do
      order.distributor.hide_ofn_navigation = true
    end

    it 'does not display the OFN header and logo' do
      expect(public_send(mail).body).not_to include(ContentConfig.url_for(:logo))
    end
  end
end
