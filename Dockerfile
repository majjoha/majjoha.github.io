FROM ruby:2.6-alpine

ADD . /app
WORKDIR /app

RUN apk add --virtual build-dependencies build-base libffi-dev
RUN gem install bundler
RUN bundle install --jobs 4
RUN apk del build-dependencies

EXPOSE 4000

CMD ["jekyll", "serve", "--watch", "--host=0.0.0.0"]
