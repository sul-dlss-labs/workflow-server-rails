# frozen_string_literal: true

##
# Parsing Workflow XML
class WorkflowCreator
  attr_reader :parser, :version

  ##
  # @param [WorkflowParser] parser
  # @param [Version] version the object/version
  def initialize(parser:, version:)
    @parser = parser
    @version = version
  end

  ##
  # Delete all the rows for this druid/version/workflow, and replace with new rows.
  # @return [Array]
  def create_workflow_steps
    ActiveRecord::Base.transaction do
      version.workflow_steps.where(workflow: workflow_id).destroy_all

      # Any steps for this object/workflow that are not the current version are marked as not active.
      WorkflowStep.where(workflow: workflow_id, druid: version.druid).update(active_version: false)

      processes.map do |process|
        WorkflowStep.create!(workflow_attributes(process))
      end
    end
  end

  private

  delegate :processes, :workflow_id, to: :parser

  def workflow_attributes(process)
    {
      workflow: workflow_id,
      druid: version.druid,
      process: process.process,
      status: process.status,
      lane_id: process.lane_id,
      repository: version.repository,
      lifecycle: process.lifecycle,
      version: version.version_id,
      active_version: true
    }
  end
end