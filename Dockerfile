FROM ruby:2.5.1

RUN apt-get update && apt-get install -y build-essential libpq-dev vim

ARG APP_HOME
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
