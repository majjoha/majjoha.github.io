FROM ruby:2.6

ADD . /app
WORKDIR /app

RUN gem install bundler
RUN bundle install --jobs 4

EXPOSE 4000

CMD ["jekyll", "serve", "--watch", "--host=0.0.0.0"]
