FROM ruby:3.1.2-alpine3.15

ENV APP_DIR="/usr/src/app/" \
    BUNDLE_WITHOUT="development test" \
    APP_ENV="production"

WORKDIR $APP_DIR
COPY . $APP_DIR

RUN set -ex && \
    apk update && \
    apk add build-base

RUN bundle config set without $BUNDLE_WITHOUT
RUN --mount=type=ssh bundle install --jobs 4 --retry 5

CMD ["bundle", "exec", "ruby", "app.rb"]
