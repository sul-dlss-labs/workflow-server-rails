# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show a workflow template', type: :request do
  context 'for an existent template' do
    it 'draws an empty set of milestones' do
      get '/workflow_templates/assemblyWF'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['processes']).to eq [
        { 'label' => 'Initiate assembly of the object',
          'name' => 'start-assembly' },
        { 'label' => 'Create content-metadata from stub content metadata if it exists',
          'name' => 'content-metadata-create' },
        { 'label' => 'Create JP2 derivatives for any images in object',
          'name' => 'jp2-create' },
        { 'label' => 'Compute and compare checksums for any files referenced in contentMetadata',
          'name' => 'checksum-compute' },
        { 'label' => 'Calculate and add exif, mimetype, file size and other attributes to each file node in contentMetadata',
          'name' => 'exif-collect' },
        { 'label' => 'Initiate workspace and start common accessioning',
          'name' => 'accessioning-initiate' }
      ]
    end
  end

  context 'for an nonexistent template' do
    it 'returns 400' do
      get '/workflow_templates/foo'
      expect(response).to have_http_status(:bad_request)
    end
  end
end
