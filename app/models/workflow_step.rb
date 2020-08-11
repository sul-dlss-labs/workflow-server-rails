# frozen_string_literal: true

# Models a process that occurred for a digital object. Basically a log entry.
class WorkflowStep < ApplicationRecord
  validate :druid_is_valid
  validates :workflow, presence: true
  validates :process, presence: true
  validates :version, numericality: { only_integer: true }
  validates :status, inclusion: { in: %w[waiting started completed queued error skipped] }
  validates :process, uniqueness: { scope: %w[version workflow druid] }
  validate  :workflow_exists, on: :create
  validate  :process_exists_for_workflow, on: :create

  before_save :set_completed_at, if: :completed?

  scope :lifecycle, -> { where.not(lifecycle: nil) }
  scope :incomplete, -> { where.not(status: COMPLETED_STATES) }
  scope :complete, -> { where(status: COMPLETED_STATES) }
  scope :waiting, -> { where(status: 'waiting') }
  scope :queued, -> { where(status: 'queued') }
  scope :started, -> { where(status: 'started') }
  scope :active, -> { where(active_version: true) }

  scope :for_version, ->(version) { where(version: version) }

  COMPLETED_STATES = %w[completed skipped].freeze # a list of states that are considered completed
  ##
  # Serialize a WorkflowStep as a milestone
  # @param [Nokogiri::XML::Builder] xml
  # @return [Nokogiri::XML::Builder::NodeBuilder]
  def as_milestone(xml)
    xml.milestone(lifecycle,
                  date: milestone_date,
                  version: version)
  end

  # callback to set the completed_at column to the current time if we are completing a step
  def set_completed_at
    self.completed_at = Time.now
  end

  ##
  # indicate if this step is marked as completed
  # @return [boolean]
  def completed?
    COMPLETED_STATES.include? status
  end

  ##
  # this is the milestone completion date, which is listed as the date the row was created, or the date it was completed
  def milestone_date
    if completed_at
      completed_at.to_time.iso8601
    else
      created_at.to_time.iso8601
    end
  end

  ##
  # check if we have a valid druid with prefix
  # @return [boolean]
  def valid_druid?
    DruidTools::Druid.valid?(druid, true) && druid.starts_with?('druid:')
  end

  ##
  # check if the named workflow has a current definition
  # @return [boolean]
  def valid_workflow?
    WorkflowTemplateLoader.new(workflow).exists?
  end

  ##
  # check if the named process step is currently defined in the named workflow
  # @return [boolean]
  def valid_process_for_workflow?
    return false unless valid_workflow?

    wtp = WorkflowTemplateParser.new(WorkflowTemplateLoader.new(workflow).load_as_xml)
    wtp.processes.map(&:name).include? process
  end

  # ensure we have a valid druid with prefix
  def druid_is_valid
    errors.add(:druid, 'is not valid') unless valid_druid?
  end

  # ensure we have a valid workflow before creating a new step
  def workflow_exists
    errors.add(:workflow, 'is not valid') unless valid_workflow?
  end

  # ensure we have a valid process before creating a new step
  def process_exists_for_workflow
    errors.add(:process, 'is not valid') unless valid_process_for_workflow?
  end

  # rubocop:disable Metrics/MethodLength
  def attributes_for_process
    {
      version: version,
      note: note,
      lifecycle: lifecycle,
      laneId: lane_id,
      elapsed: elapsed,
      attempts: attempts,
      datetime: updated_at.to_time.iso8601,
      status: status,
      name: process
    }.tap do |attr|
      attr[:errorMessage] = error_msg if error_msg
    end
  end
  # rubocop:enable Metrics/MethodLength
end
