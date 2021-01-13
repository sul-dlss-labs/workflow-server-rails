# Workflow service

[![CircleCI](https://circleci.com/gh/sul-dlss/workflow-server-rails.svg?style=svg)](https://circleci.com/gh/sul-dlss/workflow-server-rails)
[![Test Coverage](https://api.codeclimate.com/v1/badges/cc78d20264a4eaf8a782/test_coverage)](https://codeclimate.com/github/sul-dlss/workflow-server-rails/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/cc78d20264a4eaf8a782/maintainability)](https://codeclimate.com/github/sul-dlss/workflow-server-rails/maintainability)
[![](https://images.microbadger.com/badges/image/suldlss/workflow-server.svg)](https://microbadger.com/images/suldlss/workflow-server "Get your own image badge on microbadger.com")
[![OpenAPI Validator](http://validator.swagger.io/validator?url=https://raw.githubusercontent.com/sul-dlss/workflow-server-rails/master/openapi.yml)](http://validator.swagger.io/validator/debug?url=https://raw.githubusercontent.com/sul-dlss/workflow-server-rails/master/openapi.yml)

This is a Rails-based workflow service that replaced SDR's Java-based workflow service.  It is consumed by the users of dor-workflow-client (argo, hydrus, hydra_etd, pre-assembly, dor-indexing-app, robots) and *soon* the goobi application (currently proxying through dor-services-app).

The workflows are defined by xml templates which are stored in [config/workflows](https://github.com/sul-dlss/workflow-server-rails/tree/main/config/workflows).  The templates define a dependency graph. When all prerequisites for a step are complete, the step is marked as "queued" and a corresponding job is pushed into Resque.  Some steps are are marked `skip-queue="true"` which means they are merely logged events and do not kick off a Resque process.


## Resque Jobs

When a workflow step is set to done, the service calculates which workflow steps
are ready to be worked on and enqueues Resque jobs for them.  The queues are named
for the workflow and priority.  For example:

```
accessionWF_high
accessionWF_default
accessionWF_low
assemblyWF_high
assemblyWF_default
assemblyWF_low
disseminationWF_high
disseminationWF_default
disseminationWF_low
...
```

## Developers

### Build
Build the production image:
```
docker build -t suldlss/workflow-server:latest .
```

### Run the development stack
```
$ docker-compose up -d
[FIRST RUN]
$ docker-compose run app rake db:setup
$ docker-compose stop
$ docker-compose up -d
[ -------- ]
```

If you want to connect to the container:
```
$ docker ps (to retrieve the container id)
$ docker exec -it (container id) /bin/sh
```

## Testing:

You need to be running the postgres database.  One of the easiest ways is to use the docker-compose db via separate terminal window:

```
docker-compose up db
```

The first time you run tests, you may need to run this before the tests (from another terminal window):

`RAILS_ENV=test ./bin/rails db:create db:migrate`

To run tests:
```
bundle exec rspec
```

To shut down postgres afterwards,

- cntl-C in your existing docker-compose terminal window.
- ```docker-compose down``` afterwards

## Routes:
`GET    /:repo/objects/:druid/lifecycle` - Returns the milestones in the lifecycle that have been completed

`GET    /objects/:druid/lifecycle` - Returns the milestones in the lifecycle that have been completed


`POST   /:repo/objects/:druid/versionClose` - Set all versioningWF steps to 'complete' and starts a new accessionWF unless `create-accession=false` is passed as a parameter.


These methods deal with the workflow for a single object
```
POST   /objects/:druid/workflows/:workflow
GET    /:repo/objects/:druid/workflows
GET    /:repo/objects/:druid/workflows/:workflow
DELETE /:repo/objects/:druid/workflows/:workflow
```

These methods deal with a single step for a single object
```
PUT    /:repo/objects/:druid/workflows/:workflow/:process
GET    /:repo/objects/:druid/workflows/:workflow/:process
```

Return the list of workflow templates
`GET   /workflow_templates`

Return the list of steps for the given workflow template
`GET   /workflow_templates/:workflow`

`GET    /workflow_archive` - Deprecated. Currently just returns a count of the number of items/versions for the workflow
`PUT    /:repo/objects/:druid/workflows/:workflow` - Deprecated. Use version without repo parameter instead.

These processes are used by robot-master to discover which steps need to be performed.
```
GET    /workflow_queue/lane_ids
GET    /workflow_queue/all_queued
GET    /workflow_queue
```

## Deploy
### Logs
Logs are located in `/var/log/httpd`.

## TODO

### Remove the STOMP dependency
It would be great if we could remove the dependency on STOMP messaging.
One way we could do this is if we only allow update messages to come from dor-services-app.
dor-services-app could send a message to STOMP.

Another possibility would be removing the workflow status from the Argo SOLR index.
If something needs to know about statuses, it should ask the workflow service directly.
