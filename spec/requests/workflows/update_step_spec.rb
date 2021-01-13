# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update a workflow step for an object', type: :request do
  let(:druid) { wf.druid }

  let(:process_xml) do
    '<process name="start-accession" status="completed" elapsed="3" note="Yay"/>'
  end

  before do
    allow(SendUpdateMessage).to receive(:publish)
  end

  context 'with XML indicating success' do
    let(:wf) do
      FactoryBot.create(:workflow_step,
                        status: 'error',
                        error_msg: 'Bang!',
                        error_txt: 'This is error',
                        lifecycle: 'submitted')
    end

    it 'clears the old error message, but preserves the lifecycle' do
      put "/dor/objects/#{druid}/workflows/#{wf.workflow}/#{wf.process}", params: process_xml
      wf.reload
      expect(wf.status).to eq 'completed'
      expect(wf.error_msg).to be_nil
      expect(wf.error_txt).to be_nil

      expect(wf.lifecycle).to eq 'submitted'

      expect(response.body).to eq '{"next_steps":[]}'
      expect(SendUpdateMessage).to have_received(:publish).with(druid: wf.druid)
    end
  end

  context 'with a non-default lane_id' do
    let(:wf) do
      FactoryBot.create(:workflow_step, lane_id: 'low')
    end

    it 'does not change the lane_id' do
      put "/dor/objects/#{druid}/workflows/#{wf.workflow}/#{wf.process}", params: process_xml

      wf.reload
      expect(wf.status).to eq 'completed'
      expect(wf.lane_id).to eq 'low'
      expect(response.body).to eq '{"next_steps":[]}'
      expect(SendUpdateMessage).to have_received(:publish).with(druid: wf.druid)
    end
  end

  context 'when no matching step exists (Hydrus does this)' do
    let(:druid) { 'druid:zz696qh8598' }
    let(:wf) { WorkflowStep.where(druid: druid, workflow: 'hydrusAssemblyWF', process: 'submit') }
    let(:process_xml) { '<process name="submit" status="completed" elapsed="3" lifecycle="submitted" laneId="default" note="Yay"/>' }

    it 'returns a 404' do
      put "/dor/objects/#{druid}/workflows/hydrusAssemblyWF/submit", params: process_xml

      expect(response).to be_not_found
      expect(SendUpdateMessage).not_to have_received(:publish).with(druid: druid)
    end
  end

  context 'with error XML' do
    let(:wf) { FactoryBot.create(:workflow_step) }

    let(:process_xml) do
      '<process name="start-accession" status="error" errorMessage="failed to do the thing" errorText="box1.foo.edu"/>'
    end

    it 'updates the step with error message/text' do
      put "/dor/objects/#{druid}/workflows/#{wf.workflow}/#{wf.process}", params: process_xml

      expect(wf.reload.status).to eq 'error'
      expect(response.body).to eq '{"next_steps":[]}'
      expect(SendUpdateMessage).to have_received(:publish).with(druid: wf.druid)
    end
  end

  context 'when process names do not match' do
    let(:wf) { FactoryBot.create(:workflow_step) }

    let(:process_xml) do
      '<process name="other-metadata" status="completed"/>'
    end

    it 'returns a 400 and does not update the step' do
      expect_any_instance_of(WorkflowStep).not_to receive(:update)

      put "/dor/objects/#{druid}/workflows/#{wf.workflow}/#{wf.process}", params: process_xml

      expect(response).to be_bad_request
      expect(SendUpdateMessage).not_to have_received(:publish)
    end
  end

  context 'when current-status is set' do
    let(:wf) { FactoryBot.create(:workflow_step) }

    context 'and it does not match the current status' do
      it 'does not update the step' do
        expect_any_instance_of(WorkflowStep).not_to receive(:update)

        put "/dor/objects/#{druid}/workflows/#{wf.workflow}/#{wf.process}?current-status=not-waiting", params: process_xml

        # NOTE: `#be_conflict` does not exist as a matcher for 409 errors
        expect(response.status).to eq 409
        expect(SendUpdateMessage).not_to have_received(:publish)
      end
    end

    context 'and it matches the current status' do
      let(:wf) { FactoryBot.create(:workflow_step, status: 'waiting') }

      it 'updates the step' do
        put "/dor/objects/#{druid}/workflows/#{wf.workflow}/#{wf.process}?current-status=waiting", params: process_xml

        expect(wf.reload.status).to eq 'completed'
        expect(response.body).to eq '{"next_steps":[]}'
        expect(SendUpdateMessage).to have_received(:publish).with(druid: wf.druid)
      end
    end

    context 'when there are multiple versions' do
      let(:version1_step) do
        FactoryBot.create(:workflow_step,
                          status: 'error',
                          version: 1)
      end
      let(:version2_step) do
        FactoryBot.create(:workflow_step,
                          status: 'error',
                          version: 2,
                          druid: version1_step.druid)
      end

      before do
        # Force create
        version1_step
        version2_step
      end

      it 'updates the newest version' do
        put "/dor/objects/#{version1_step.druid}/workflows/#{version1_step.workflow}/#{version1_step.process}", params: process_xml

        version1_step.reload
        expect(version1_step.status).to eq 'error'

        version2_step.reload
        expect(version2_step.status).to eq 'completed'

        expect(response.body).to eq '{"next_steps":[]}'
        expect(SendUpdateMessage).to have_received(:publish).with(druid: version1_step.druid)
      end
    end
  end

  describe 'PUT update' do
    let(:druid) { first_step.druid }
    let(:workflow_id) { 'accessionWF' }
    let(:first_step) { FactoryBot.create(:workflow_step, status: 'completed') } # start-accession, which is already completed

    before do
      FactoryBot.create(:workflow_step, druid: druid, process: 'descriptive-metadata')
      FactoryBot.create(:workflow_step, druid: druid, process: 'rights-metadata')
      allow(SendUpdateMessage).to receive(:publish)
      allow(QueueService).to receive(:enqueue)
    end

    context 'when updating a step' do
      let(:body) { '<process name="descriptive-metadata" status="error" />' }

      it 'updates the step with repository (Deprecated)' do
        put "/dor/objects/#{druid}/workflows/#{workflow_id}/descriptive-metadata", params: body
        expect(response.body).to eq('{"next_steps":[]}')
        expect(SendUpdateMessage).to have_received(:publish).with(druid: druid)
        expect(WorkflowStep.find_by(druid: druid, process: 'descriptive-metadata').status).to eq('error')
        expect(QueueService).to_not have_received(:enqueue)
      end

      it 'verifies the current status' do
        put "/dor/objects/#{druid}/workflows/#{workflow_id}/descriptive-metadata?current-status=not-waiting", params: body
        expect(response.body).to eq('Status in params (not-waiting) does not match current status (waiting)')
        expect(response.code).to eq('409')
      end

      it 'verifies that process in url and body match' do
        put "/dor/objects/#{druid}/workflows/#{workflow_id}/rights-metadata", params: body
        expect(response.body).to eq('Process name in body (descriptive-metadata) does not match process name in URI ' \
                                    '(rights-metadata)')
        expect(response.code).to eq('400')
      end
    end

    context 'when updating a step without a repository' do
      let(:body) { '<process name="descriptive-metadata" status="error" />' }

      it 'updates the step' do
        put "/objects/#{druid}/workflows/#{workflow_id}/descriptive-metadata", params: body

        expect(SendUpdateMessage).to have_received(:publish).with(druid: druid)
        expect(WorkflowStep.find_by(druid: druid, process: 'descriptive-metadata').status).to eq('error')
        expect(QueueService).to_not have_received(:enqueue)
      end

      it 'verifies the current status' do
        put "/objects/#{druid}/workflows/#{workflow_id}/descriptive-metadata?current-status=not-waiting", params: body
        expect(response.body).to eq('Status in params (not-waiting) does not match current status (waiting)')
        expect(response.code).to eq('409')
      end

      it 'verifies that process in url and body match' do
        put "/objects/#{druid}/workflows/#{workflow_id}/rights-metadata", params: body
        expect(response.body).to eq('Process name in body (descriptive-metadata) does not match process name in URI ' \
                                    '(rights-metadata)')
        expect(response.code).to eq('400')
      end

      it 'verifies that process is unique' do
        duplicate = FactoryBot.build(:workflow_step, druid: druid, process: 'rights-metadata', version: first_step.version)
        duplicate.save(validate: false)

        expect do
          put "/objects/#{druid}/workflows/#{workflow_id}/rights-metadata", params: body
        end.to raise_error "Duplicate workflow step for #{first_step.druid} accessionWF rights-metadata"
      end
    end

    context 'when completing a step' do
      let(:body) { '<process name="descriptive-metadata" status="completed" />' }
      it 'updates the step and enqueues next step' do
        put "/dor/objects/#{druid}/workflows/#{workflow_id}/descriptive-metadata", params: body
        expect(response.body).to match(/rights-metadata/)
        expect(SendUpdateMessage).to have_received(:publish).with(druid: druid)
        expect(WorkflowStep.find_by(druid: druid, process: 'descriptive-metadata').status).to eq('completed')
        expect(QueueService).to have_received(:enqueue).with(WorkflowStep.find_by(druid: druid,
                                                                                  process: 'rights-metadata'))
      end
    end
  end
end
