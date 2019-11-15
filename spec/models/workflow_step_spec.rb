# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStep do
  subject(:step) do
    FactoryBot.create(
      :workflow_step,
      workflow: 'accessionWF',
      process: 'start-accession',
      lifecycle: 'submitted'
    )
  end

  it { is_expected.to be_valid }

  context 'without required values' do
    subject { described_class.create }

    it { is_expected.not_to be_valid }
  end

  context 'without valid status' do
    it 'is not valid if the status is nil' do
      expect { step.status = nil }.to change { step.valid? }.from(true).to(false)
    end

    it 'is not valid if the status is a bogus value' do
      expect { step.status = 'bogus' }.to change { step.valid? }.from(true).to(false)
    end
  end

  context 'when step already exists for the same druid/workflow/version' do
    subject(:dupe_step) do
      described_class.new(
        druid: step.druid,
        workflow: step.workflow,
        process: step.process,
        version: step.version,
        status: 'completed',
        repository: 'dor'
      )
    end

    it 'includes an informative error message' do
      expect(dupe_step).not_to be_valid
      expect(dupe_step.errors.messages).to include(process: ['has already been taken'])
    end
  end

  context 'with non-existent workflow name' do
    subject(:bogus_workflow) do
      described_class.new(
        druid: subject.druid,
        workflow: 'bogusWF',
        process: subject.process,
        version: subject.version,
        status: subject.status,
        repository: subject.repository
      )
    end

    it 'does not create a new workflow step' do
      expect(bogus_workflow).not_to be_valid
      expect(bogus_workflow.errors.messages).to include(workflow: ['is not valid'])
    end
  end

  context 'with nil workflow name' do
    subject(:bogus_workflow) do
      described_class.new(
        druid: subject.druid,
        workflow: nil,
        process: subject.process,
        version: subject.version,
        status: subject.status,
        repository: subject.repository
      )
    end

    it 'does not create a new workflow step' do
      expect(bogus_workflow).not_to be_valid
      expect(bogus_workflow.errors.messages).to include(workflow: ['is not valid'])
    end
  end

  context 'with non-existent process name' do
    subject(:bogus_process) do
      described_class.new(
        druid: subject.druid,
        workflow: subject.workflow,
        process: 'bogus-step',
        version: subject.version,
        status: subject.status,
        repository: subject.repository
      )
    end

    it 'is not possible to create a new workflow step for a non-existent or missing process value' do
      expect(bogus_process).not_to be_valid
      expect(bogus_process.errors.messages).to include(process: ['is not valid'])
    end
  end

  context 'with nil process name' do
    subject(:bogus_process) do
      described_class.new(
        druid: subject.druid,
        workflow: subject.workflow,
        process: nil,
        version: subject.version,
        status: subject.status,
        repository: subject.repository
      )
    end

    it 'is not possible to create a new workflow step for a non-existent or missing process value' do
      expect(bogus_process).not_to be_valid
      expect(bogus_process.errors.messages).to include(process: ['is not valid'])
    end
  end

  context 'with invalid version' do
    [nil, 'bogus', 4.3, ''].each do |invalid_version|
      it "is not valid if the version is #{invalid_version}" do
        expect { step.version = invalid_version }.to change { step.valid? }.from(true).to(false)
      end
    end
  end

  describe '#as_milestone' do
    subject(:parsed_xml) { Nokogiri::XML(builder.to_xml) }

    let!(:builder) do
      Nokogiri::XML::Builder.new do |xml|
        step.as_milestone(xml)
      end
    end

    it 'serializes a Workflow as a milestone' do
      expect(parsed_xml.at_xpath('//milestone')).to include ['date', //], ['version', /1/]
      expect(parsed_xml.at_xpath('//milestone').content).to eq 'submitted'
    end
  end

  describe '#attributes_for_process' do
    it 'includes the expected values' do
      expect(step.attributes_for_process).to include(
        version: 1,
        note: nil,
        lifecycle: 'submitted',
        laneId: 'default',
        elapsed: nil,
        attempts: 0,
        datetime: String,
        status: 'waiting',
        name: 'start-accession'
      )
    end
  end
end
