FROM ruby:2.2.0

RUN apt-get update && \
  apt-get install -y qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x

ENV app /usr/src/app

# Create app directory
RUN mkdir -p $app
WORKDIR $app

# Bundle app source
COPY . $app

# Install app dependencies
RUN bundle install

# dumb-init
ADD dumb-init_1.2.0 /usr/bin/dumb-init
RUN chmod +x /usr/bin/dumb-init

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "bundle", "exec", "rails", "server" ]
