# BigBlueButton on Rails [<img src="http://travis-ci.org/mconf/bigbluebutton_rails.png"/>](http://travis-ci.org/mconf/bigbluebutton_rails)

[BigBlueButton](http://bigbluebutton.org) integration for Ruby on Rails 4.

Features:

* Allows multiple servers and multiple conference rooms.
* Full API access using
    [bigbluebutton-api-ruby](https://github.com/mconf/bigbluebutton-api-ruby).
* Easy way to join conferences: simply create a room and call the `join`
    action.
* Easy integration with authentication and authorization mechanisms, such as
    [Devise](https://github.com/plataformatec/devise) and
    [CanCan](https://github.com/ryanb/cancan).
* Support for recordings: meetings can be recorded, the list of recordings
    retrieved and recordings can be played.
* Possibility to create private rooms, that require a password to join.
* Deals with visitors (users that are not logged), allowing (or forbidding)
    them to join rooms.
* Uses static meeting IDs generated as a globally unique identifier (e.g.
    `36mskja87-029i-lsk9-b96e-98278407e145-1365703324`).
* Stores a registry of meetings that happened and associates them with the
    recording that was generated for it (if any).
* Allows rooms to be configured dynamically using the
    `{config.xml}[https://code.google.com/p/bigbluebutton/wiki/ClientConfigura
    tion]` feature.
* Automatic detection of the user-agent to automatically trigger the [mobile
    client](https://github.com/bigbluebutton/bbb-air-client) when joining a
    conference from a mobile device.


Possible future features:

* Limit the number of users per room and rooms per server.
* Server administration (use `bbb-conf`, etc).
* Pre-upload of slides.
* See
    [TODO.md](https://github.com/mconf/bigbluebutton_rails/blob/master/TODO.md).


## Supported versions

This gem is mainly used with [Mconf-Web](https://github.com/mconf/mconf-web).
You can always use it as a reference for verions of dependencies and examples of how to use the gem.


### BigBlueButton

The current version of this gem supports `all` the following versions of
BigBlueButton:

* 1.0
* 0.9
* 0.81
* 0.8


### Ruby

Tested in rubies:

Requires ruby >= 1.9.3.

* ruby-2.3 **recommended**
* ruby-2.2
* ruby-2.1
* ruby-1.9.3 (last tested with p484)


Use these versions to be sure it will work. Other patches of these versions
should work as well.

### Rails

To be used with **Rails 4** only. Currently tested with Rails 4.1.

Version 1.4.0 was the last one to support Rails 3.2. To use it, use the tag
[`v1.4.0`](https://github.com/mconf/bigbluebutton_rails/tree/v1.4.0).

### Database

We recommend the use of MySQL in your application, since this gem is developed
and tested using it.


## Upgrade

When updating the gem to a newer version, there are usually extra steps you'll have to take in order to have the database migrated, the dependencies updated, and others. These steps are described in [our wiki](https://github.com/mconf/bigbluebutton_rails/wiki). See:

* [Migrate to 1.4.0](https://github.com/mconf/bigbluebutton_rails/wiki/Migrate-to-1.4.0)
* [Migrate to 1.3.0](https://github.com/mconf/bigbluebutton_rails/wiki/Migrate-to-1.3.0)


## Installation

You can install the latest version of BigbluebuttonRails using RubyGems:

    gem install bigbluebutton_rails

Or simply add the following line in your Gemfile:

    gem "bigbluebutton_rails"

After installing, you need to run the generator:

    rails generate bigbluebutton_rails:install

This generator will create the files needed to setup the gem in your
application. You should take some time to open all the files generated and
analyze them.

By default the gem will use the views it provides, **but it is strongly
recommended that you adapt them for your needs!** The views provided are just
an example of how they can be implemented in your application and they depend
on jQuery (use the gem `jquery-rails`) and on a css file provided by this gem.
You can easily generate the views and the css file in your application to
later customize them with:

    rails generate bigbluebutton_rails:views

To now more about the generators see [How to:
Generators](https://github.com/mconf/bigbluebutton_rails/wiki/How-to:-Generators)

#### Dependencies

Since version 1.4.0, this gem depends on
[Resque](https://github.com/defunkt/resque), and since 2.0.0 it also uses
[Resque-scheduler](https://github.com/resque/resque-scheduler).

These gems are used to run background jobs. The ones we have right now are:
update the list of recordings, check for meetings that started or ended to
update the database.

The gem already requires all dependencies, so you don't have to include them
in your Gemfile. But you need to configure your application to use Resque and
Resque-scheduler.

To do so, copy the following files to your application:

* `config/resque/resque.rake` to your application's `lib/tasks/`;
* `config/resque/workers_schedule.yml` to your application's `config/`.


The first is a rake task to trigger Resque and Resque-scheduler. The second is
the scheduling of tasks used by Resque-scheduler. If you already use these
gems in your application, you probably already have these files. So you can
just merge them together.

To run Resque and Resque-scheduler you will need to run the take tasks:

    QUEUE="bigbluebutton_rails" rake resque:work
    rake resque:scheduler

These gems use [redis](http://redis.io/) to store their data, so you will need
it in your server. If you're on Ubuntu, you can install it with:

    apt-get install redis-server

Please refer to the documentation of
[Resque](https://github.com/defunkt/resque) and
[Resque-scheduler](https://github.com/resque/resque-scheduler) to learn more
about them and how to use them in development or production.

### Routes

The routes to BigbluebuttonRails can be generated with the helper
`bigbluebutton_routes`. See the example below:

    bigbluebutton_routes :default

It will generate the default routes. You need to call it at least once and the
routes will be scoped with 'bigbluebutton'. They will look like:

    /bigbluebutton/servers
    /bigbluebutton/servers/my-server/new
    /bigbluebutton/servers/my-server/rooms
    /bigbluebutton/rooms
    /bigbluebutton/rooms/my-room/join

You can also make the routes use custom controllers:

    bigbluebutton_routes :default, :controllers => {
      :servers => 'custom_servers',
      :rooms => 'custom_rooms',
      :recordings => 'custom_recordings'
    }

To generate routes for a single controller:

    bigbluebutton_routes :default, :only => 'servers'

You may also want shorter routes to access conference rooms. For that, use the
option `room_matchers`:

    resources :users do
      bigbluebutton_routes :room_matchers
    end

It creates routes to the actions used to access a conference room, so you can
allow access to webconference rooms using URLs such as:

    http://myserver.com/my-community/room-name/join
    http://myserver.com/user-name/room-name/join

For more information see:

* [How to: Routes](https://github.com/mconf/bigbluebutton_rails/wiki/How-to:-Routes)


### Basic configuration

There are some basic assumptions made by BigbluebuttonRails:

* You have a method called `current_user` that returns the current user;
* The `current_user` has an attribute or method called "name" that returns
  his/her fullname and an attribute or method "id" that returns the ID.


If you don't, you can change this behaviour easily, keep reading.

BigbluebuttonRails uses the methods `bigbluebutton_user` and
`bigbluebutton_role(room)` to get the current user and to get the permission
that the current user has in the `room`, respectively. These methods are
defined in
`{lib/bigbluebutton_rails/controller_methods.rb}[https://github.com/mconf/bigb
luebutton_rails/blob/master/lib/bigbluebutton_rails/controller_methods.rb]`
and you can reimplement them in your application controller to change their
behaviour as shown below.

    class ApplicationController < ActionController::Base

      # overriding bigbluebutton_rails function
      def bigbluebutton_user
        current_user && current_user.is_a?(User) ? current_user : nil
      end

      def bigbluebutton_role(room)
        ...
      end

    end

### Updating the recordings

Since this task can consume quite some time if your server has a lot of
recordings, it is recommended to run it periodically in the background. It is
already done by the application if you are running Resque and Resque-scheduler
properly. But this gem also provides a rake task to fetch the recordings from
the web conference servers and update the application database.

The command below will fetch recordings for **all servers** and update the
database with all recordings found:

    rake bigbluebutton_rails:recordings:update

* [How recordings work](https://github.com/mconf/bigbluebutton_rails/wiki/How-Recordings-Work)


### Updating the list of meetings

Meetings (`BigbluebuttonMeeting` models) in BigbluebuttonRails are instances
of meetings that were held in web conference rooms. A meeting is created
whenever the application detects that a user joined a room and that he's the
first user. Meetings are never removed, they are kept as a registry of what
happened in the web conference servers connected to BigbluebuttonRails.

The creating of these objects is done in background using a gem called
[resque](https://github.com/defunkt/resque). Whenever a user clicks in the
button to join a meeting, a resque worker is scheduled. This worker will wait
for a while until the meeting is created and running in the web conference
server, and will then create the corresponding `BigbluebuttonMeeting` object.

To keep track of meetings, you have to run the resque workers (this is needed
both in development and in production):

    rake resque:work QUEUE='bigbluebutton_rails'

The list of meetings is also periodically synchronized using Resque-scheduler
(see the sections above).

### Associating rooms and servers

Rooms must be associated with a server to function. When a meeting is created,
it is created in the server that's associated with the room.
By default, this gem automatically selects a server **if one is needed and the
room has no server yet**.

To change this behavior, applications can override the configuration
`BigbluebuttonRails.configuration.select_server`. This attribute receives a
function that will be called inside all methods that trigger API calls,
methods that need a server to work properly. It receives a parameter that
indicates which API call will be sent to the server and expects the function
to return a `BigbluebuttonServer`.

One common use would be to override this method to always select a new server
when a meeting is created (when the argument received is `:create`). This
would allow the implementation of a simple load balancing mechanism.

To configure it, add a code like the one below to one initializer in your
application:

```ruby
BigbluebuttonRails.configure do |config|
  config.select_server = Proc.new do |room, api_method=nil|
    if room.name == 'special-room'
      BigbluebuttonServer.find_by(name: 'special-server')
    else
      BigbluebuttonServer.first
    end
  end
end
```


### Example application

If you need more help to set up the gem or just want to see an example of it
working, check out the test application at `spec/rails_app/`!

#### See also

* [How to: Integrate with Devise](https://github.com/mconf/bigbluebutton_rails/wiki/How-to:-Integrate-with-Devise)
* [How to: Integrate with CanCan](https://github.com/mconf/bigbluebutton_rails/wiki/How-to:-Integrate-with-CanCan)


## Contributing/Development

To setup an environment, first copy `spec/rails_app/config/database.yml.example` to
`spec/rails_app/config/database.yml`. It uses MySQL since this is the database
recommended for the applications that use this gem.

You can start the example application (from `spec/rails_app`) with:

    docker-compose up dev

It will probably not work straight away, because you need to setup the application first.
Do so with:

    docker-compose run dev rake rails_app:install
    docker-compose run dev rake rails_app:db

    # optionally:
    docker-compose run dev rake rails_app:populate # to create fake data

Then try the `up dev` command again and it should open up a server. Access `localhost:3000`
to see it.

To run the tests the process is exactly the same, just replace the `dev` target with `test`:

    docker-compose up test

If you're adding migrations to the gem, test them with:

    docker-compose run test rake spec:migrations

If you need to keep track of meetings, run the resque workers with:

    docker-compose run dev rake resque:work QUEUE='bigbluebutton_rails'

If you want your code to be integrated in this repository, please fork it,
create a branch with your modifications and submit a pull request.

* See more about testing [in our wiki page](https://github.com/mconf/bigbluebutton_rails/wiki/Testing).


### Test Coverage

Coverage is analyzed by default when you run:

    docker-compose up test

Run it and look at the file `coverage/index.html`.

### Best Practices

We use the gem `rails_best_practices` to get some nice tips on how to improve
the code.

Run:

    docker-compose run dev rake best_practices

And look at the file `rails_best_practices_output.html` to see the tips.

## License

Distributed under The MIT License (MIT). See
[LICENSE](https://github.com/mconf/bigbluebutton_rails/blob/master/LICENSE).

## Contact

This project is developed as part of Mconf (http://mconf.org).

Mailing list:
* mconf-dev@googlegroups.com

Contact:
* Mconf: A scalable opensource multiconference system for web and mobile devices
* PRAV Labs - UFRGS - Porto Alegre - Brazil
* http://www.inf.ufrgs.br/prav/gtmconf
