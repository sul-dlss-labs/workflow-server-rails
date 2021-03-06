# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NextStepService do
  describe '.for' do
    subject(:next_steps) { described_class.for(step: step) }

    context "when there is a step that isn't complete" do
      let(:step) do
        FactoryBot.create(:workflow_step,
                          process: 'start-accession',
                          version: 1,
                          status: 'completed',
                          active_version: true)
      end

      let!(:ready) do
        FactoryBot.create(:workflow_step,
                          druid: step.druid,
                          process: 'descriptive-metadata',
                          version: 1,
                          status: 'waiting',
                          active_version: true)
      end

      before do
        # This record does not have the prerequisites met, so it shouldn't appear in the results
        FactoryBot.create(:workflow_step,
                          druid: step.druid,
                          process: 'rights-metadata',
                          version: 1,
                          status: 'waiting',
                          active_version: true)
      end

      it 'returns a list of unblocked statuses' do
        expect(next_steps).to eq [ready]
      end
    end

    context "when it's the hydrusAssemblyWF" do
      let(:step) do
        FactoryBot.create(:workflow_step,
                          process: 'start-deposit',
                          workflow: 'hydrusAssemblyWF',
                          version: 1,
                          status: 'completed',
                          active_version: true)
      end

      before do
        FactoryBot.create(:workflow_step,
                          druid: step.druid,
                          process: 'submit',
                          workflow: 'hydrusAssemblyWF',
                          version: 1,
                          status: 'waiting',
                          active_version: true)
      end

      it "returns no statuses (they're all skip-queue)" do
        expect(next_steps).to eq []
      end
    end
  end
end
