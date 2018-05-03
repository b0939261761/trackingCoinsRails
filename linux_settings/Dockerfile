FROM phusion/passenger-ruby25:0.9.30

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -f /etc/service/nginx/down

RUN rm /etc/nginx/sites-enabled/default
COPY ./webapp.conf /etc/nginx/sites-enabled/webapp.conf

ENV APP_HOME /coins
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile $APP_HOME/Gemfile
COPY Gemfile.lock $APP_HOME/Gemfile.lock
COPY . $APP_HOME

ENV BUNDLE_PATH=/coins/gems

RUN bundle check || bundle install --clean && rm -f tmp/pids/server.pid
# && bundle exec rails db:migrate

# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs




