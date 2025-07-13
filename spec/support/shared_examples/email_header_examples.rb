# frozen_string_literal: true

RSpec.shared_examples 'email header without white labelling' do |mail|
  it 'displays the OFN header by default' do
    expect(public_send(mail).body).to include(ContentConfig.url_for(:logo))
  end
end

RSpec.shared_examples 'remains unaffected by white labelling' do |mail|
  context 'when hide OFN navigation is enabled for the distributor of the order' do
    before do
      allow(order.distributor).to receive(:hide_ofn_navigation).and_return(true)
    end

    it 'still displays the OFN header' do
      expect(public_send(mail).body).to include(ContentConfig.url_for(:logo))
    end
  end
end

RSpec.shared_examples 'is affected by white labelling' do |mail|
  context 'when hide OFN navigation is enabled for the distributor of the order' do
    before do
      allow(order.distributor).to receive(:hide_ofn_navigation).and_return(true)
    end

    it 'does not display the OFN header' do
      expect(public_send(mail).body).not_to include(ContentConfig.url_for(:logo))
    end
  end
end
