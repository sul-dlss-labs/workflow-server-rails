# frozen_string_literal: true

Rails.application.routes.draw do
  scope ':repo/objects/:druid', constraints: { druid: %r{[^\/]+} }, defaults: { format: :xml } do
    get 'lifecycle', to: 'workflows#lifecycle'
    post 'versionClose', to: 'versions#close'

    # NOTE: the index route /dor/objects/:druid/workflows is encoded in the dsLocation of the workflows
    # datastream (external type) for all of our Fedora 3 objects.  We shouldn't change this endpoint.
    resources :workflows, only: %i[show index destroy], param: :workflow do
      collection do
        # Create should be a POST, but this is what the Java WFS app did.
        put ':workflow', to: 'workflows#deprecated_create'
        put ':workflow/:process', to: 'steps#update'
      end
    end
  end

  scope 'objects/:druid', constraints: { druid: %r{[^\/]+} }, defaults: { format: :xml } do
    resources :workflows, only: %i[index create], param: :workflow
  end

  get '/workflow_archive',
      to: 'workflows#archive',
      constraints: { druid: %r{[^\/]+} },
      defaults: { format: :xml }

  resource :workflow_queue, only: :show, defaults: { format: :xml } do
    collection do
      get 'lane_ids'
      get 'all_queued'
    end
  end
end
