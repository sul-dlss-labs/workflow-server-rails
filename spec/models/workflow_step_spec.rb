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
  context 'with required values' do
    it 'is valid' do
      expect(subject.valid?).to be true
    end
  end
  context 'without required values' do
    subject { described_class.create }
    it 'is not valid' do
      expect(subject.valid?).to be false
    end
  end
  describe '#as_milestone' do
    builder = {}
    before do
      builder = Nokogiri::XML::Builder.new do |xml|
        subject.as_milestone(xml)
      end
    end
    let(:parsed_xml) { Nokogiri::XML(builder.to_xml) }
    it 'serializes a Workflow as a milestone' do
      expect(parsed_xml.at_xpath('//milestone'))
        .to include ['date', //], ['version', /1/]
      expect(parsed_xml.at_xpath('//milestone').content).to eq 'submitted'
    end
  end

  describe '#attributes_for_process' do
    subject { step.attributes_for_process }
    it {
      is_expected.to include(
        version: 1,
        priority: 0,
        note: nil,
        lifecycle: 'submitted',
        laneId: 'default',
        elapsed: nil,
        attempts: 0,
        datetime: String,
        status: 'waiting',
        name: 'start-accession'
      )
    }
  end
end
