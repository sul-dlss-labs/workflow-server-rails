# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a workflow' do
  let(:wf) { FactoryBot.create(:workflow_step) }
  let(:druid) { wf.druid }
  let(:workflow_template) { WorkflowTemplateLoader.load_as_xml('accessionWF') }

  before do
    allow(QueueService).to receive(:enqueue)
  end

  describe 'deprecated PUT create' do
    let(:druid) { 'druid:bb123bb1234' }
    let(:workflow) { 'accessionWF' }
    let(:repository) { 'dor' }
    let(:request_data) { workflow_template.to_s }

    before do
      allow(SendUpdateMessage).to receive(:publish)
    end

    it 'creates new workflows' do
      headers = { 'CONTENT_TYPE' => 'application/xml' }
      expect do
        put "/#{repository}/objects/#{druid}/workflows/#{workflow}?version=1", params: request_data, headers: headers
      end.to change(WorkflowStep, :count).by(13)

      expect(SendUpdateMessage).to have_received(:publish).with(step: WorkflowStep)
    end
  end

  describe 'POST create' do
    let(:druid) { 'druid:bb123bb1234' }
    let(:workflow) { 'accessionWF' }
    let(:lane_id) { 'foo' }

    before do
      allow(SendUpdateMessage).to receive(:publish)
    end

    context 'when the version is passed' do
      it 'creates new workflows' do
        expect do
          post "/objects/#{druid}/workflows/#{workflow}?version=1"
        end.to change(WorkflowStep, :count).by(13)
        expect(WorkflowStep.last.lane_id).to eq('default')
        expect(SendUpdateMessage).to have_received(:publish).with(step: WorkflowStep)
      end

      it 'sets the lane id' do
        post "/objects/#{druid}/workflows/#{workflow}?lane-id=#{lane_id}&version=1"
        expect(WorkflowStep.last.lane_id).to eq(lane_id)
      end

      context 'and the request is bad' do
        let(:workflow) { 'xaccessionWF' }
        it 'returns a 400 error' do
          expect do
            post "/objects/#{druid}/workflows/#{workflow}?version=1"
          end.not_to change(WorkflowStep, :count)
          expect(response.status).to eq 400
        end
      end
    end
  end
end
