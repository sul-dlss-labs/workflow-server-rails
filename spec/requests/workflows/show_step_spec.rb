# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show a workflow step for an object', type: :request do
  let(:step) do
    FactoryBot.create(:workflow_step,
                      status: 'error',
                      error_msg: 'Bang!',
                      lifecycle: 'submitted')
  end

  context 'when step exists' do
    it 'clears the old error message, but preserves the lifecycle' do
      get "/dor/objects/#{step.druid}/workflows/#{step.workflow}/#{step.process}"

      expect(response).to be_successful
      expect(response.body).to be_equivalent_to <<~XML
        <process version="1" note="" lifecycle="submitted" laneId="default" elapsed="" attempts="0" datetime="#{step.updated_at.to_time.iso8601}" status="error" name="start-accession" errorMessage="Bang!"/>
      XML
    end
  end

  context 'when step does not exist' do
    it 'returns 400' do
      get "/dor/objects/#{step.druid}/workflows/#{step.workflow}/#{step.process}x"
      expect(response).to have_http_status(:bad_request)
    end
  end
end
