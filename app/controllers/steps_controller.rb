# frozen_string_literal: true

##
# API for handling requests about a specific step within an object's workflow.
class StepsController < ApplicationController
  # Update a single WorkflowStep
  # rubocop:disable Metrics/AbcSize
  def update
    parser = ProcessParser.new(process_from_request_body)
    step = find_or_create_step_for_process

    return render plain: process_mismatch_error(parser), status: :bad_request if parser.process != params[:process]

    return render plain: status_mismatch_error(step), status: :conflict if params['current-status'] && step.status != params['current-status']

    step.update(parser.to_h)
    SendUpdateMessage.publish(druid: step.druid)
    render json: { next_steps: NextStepService.for(step: step) }
  end
  # rubocop:enable Metrics/AbcSize

  # Update a single WorkflowStep and if the status was "completed", enqueue the next.
  # rubocop:disable Metrics/AbcSize
  def next
    parser = ProcessParser.new(process_from_request_body)
    step = find_or_create_step_for_process

    return render plain: process_mismatch_error(parser), status: :bad_request if parser.process != params[:process]

    return render plain: status_mismatch_error(step), status: :conflict if params['current-status'] && step.status != params['current-status']

    step.update(parser.to_h)
    SendUpdateMessage.publish(druid: step.druid)

    next_steps = NextStepService.for(step: step)
    WorkerQueue.enqueue_steps(next_steps) if step.complete?
    render json: { next_steps: next_steps }
  end
  # rubocop:enable Metrics/AbcSize

  private

  def process_mismatch_error(parser)
    "Process name in body (#{parser.process}) does not match process name in URI (#{params[:process]})"
  end

  def status_mismatch_error(step)
    "Status in params (#{params['current-status']}) does not match current status (#{step.status})"
  end

  # Only Hydrus calls this when the objects don't exist.
  # I suspect we could make Hydrus behave more "as expected", but for now it's
  # easier to just mirror the behavior of the old Java workflow service - Justin C., Jan 2019
  def find_or_create_step_for_process
    WorkflowStep.find_or_create_by(
      repository: params[:repo],
      druid: params[:druid],
      workflow: params[:workflow],
      process: params[:process],
      version: current_version
    )
  end

  def process_from_request_body
    # TODO: Confirm we do not have a use case for multiple processes when PUT'ing updates
    Nokogiri::XML(request.body.read).xpath('//process').first
  end

  def current_version
    ObjectVersionService.current_version(params[:druid])
  end
end
