FROM ruby:2.7.1-alpine

# postgresql-client is required for invoke.sh
RUN apk --no-cache add \
  postgresql-dev \
  postgresql-client \
  tzdata

# Get bundler 2.1
RUN gem install bundler

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN apk --no-cache add --virtual build-dependencies \
  build-base \
  && bundle install --without development test\
&& apk del build-dependencies

COPY . .

LABEL maintainer="Justin Coyne <jcoyne@justincoyne.com>"
LABEL description="The workflow server suitable for testing other applications in \
                   DLSS.  This should not be used for production as it uses invoke.sh \
                   which performs database migrations automatically. This could be \
                   problematic if deployed as a cluster because we don't want all \
                   nodes to try to run the migrations."
ENV RAILS_ENV=production

CMD ["./docker/invoke.sh"]
