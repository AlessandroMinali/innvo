FROM ruby:2.5

EXPOSE 9292

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY . /usr/src/app/

RUN bundle install
