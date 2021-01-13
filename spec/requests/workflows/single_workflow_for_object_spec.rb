# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get a single workflow for an object', type: :request do
  context 'when repo is supplied (deprecated)' do
    context 'when a workflow exists for the object' do
      let(:item) do
        FactoryBot.create(:workflow_step,
                          status: 'waiting',
                          created_at: date)
      end

      let(:date) { Time.now.utc.iso8601.sub(/Z/, '+00:00') }
      let(:druid) { item.druid }

      it 'shows the workflow' do
        get "/dor/objects/#{druid}/workflows/accessionWF"
        expect(response).to be_successful
        expect(response.body).to be_equivalent_to <<~XML
          <workflow objectId="#{druid}" id="accessionWF">
            <process version="1" note="" lifecycle="" laneId="default"
              elapsed="" attempts="0" datetime="#{date}"
              status="waiting" name="start-accession"/>
          </workflow>
        XML
      end
    end

    context 'when no workflow exists' do
      let(:druid) { 'druid:bb123bc1234' }

      it 'returns an empy workflow node' do
        get "/dor/objects/#{druid}/workflows/accessionWF"
        expect(response).to be_successful
        expect(response.body).to be_equivalent_to <<~XML
          <workflow objectId="#{druid}" id="accessionWF" />
        XML
      end
    end
  end

  context 'when repo is not supplied' do
    context 'when a workflow exists for the object' do
      let(:item) do
        FactoryBot.create(:workflow_step,
                          status: 'waiting',
                          created_at: date)
      end

      let(:date) { Time.now.utc.iso8601.sub(/Z/, '+00:00') }
      let(:druid) { item.druid }

      it 'shows the workflow' do
        get "/objects/#{druid}/workflows/accessionWF"
        expect(response).to be_successful
        expect(response.body).to be_equivalent_to <<~XML
          <workflow objectId="#{druid}" id="accessionWF">
            <process version="1" note="" lifecycle="" laneId="default"
              elapsed="" attempts="0" datetime="#{date}"
              status="waiting" name="start-accession"/>
          </workflow>
        XML
      end
    end

    context 'when no workflow exists' do
      let(:druid) { 'druid:bb123bb1234' }

      it 'returns an empy workflow node' do
        get "/objects/#{druid}/workflows/accessionWF"
        expect(response).to be_successful
        expect(response.body).to be_equivalent_to <<~XML
          <workflow objectId="#{druid}" id="accessionWF" />
        XML
      end
    end
  end
end
