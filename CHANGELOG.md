# Change Log

## [3.3.1] - 2021-08-27
* [#201] Remove create_time attribute from BigbluebuttonRoom model

## [3.3.0] - 2021-07-16
* [#200] Remove running attribute from BigbluebuttonRoom model

## [3.2.0] - 2021-06-15
* [#198] Fix deletion of meetings with recordings.
  When deleting a meeting with recording,
  sometimes errors occurred and the recording was kept.
  Now these errors are rescued and both are deleted.
* [#197] Now the meetings controller can be overriden on apps if necessary.
* [#196] Fix race condition of workers and improve performance.
  Now workers will run sync for each rooms, not for each server, and 
  will run 16 times for about 24h after a meeting end, 
  applications can easily customize the intervals between each job
* Fix migration.rb:
    - Add missing `BigbluebuttonRecording#state` attribute


## [3.1.2] - 2021-05-15

* [#190] Increase the size of `BigbluebuttonMeeting#title` from 80 to 255 characters. It was a column
  migrated from `BigbluebuttonRecording#description` that originally was a `text`. We saw instances of
  applications that were already using more than 80 characters.


## [3.1.1] - 2021-04-29

* [#186] Refactoring to unify meeting creation on `bigbluebuttonMeeting` model. 
  Meeting creation methods that were dispersed on `BigbluebuttonRoom` and
  `BigbluebuttonRecording` models are now unified.
* [#186] Migration to:
    - Add `internal_meeting_id` column on meetings, a GUID created internally by BBB.
    This id can be used to match recordings with their respective meetings.
    - Drop `bigbluebutton_server_configs` and `bigbluebutton_room_options` tables,
    as they are not used anymore.


## [3.1.0] - 2021-04-22

* [#183] Add guest support to private rooms.
* [#185] Fix recordings without meetings. When creating a recording, if a meeting
  is not found for it, a new one is created and associated to that recording.
  That same procedure was applied to every recording without a meeting on the
  upgrade gem migration.


## [3.0.1] - 2020-03-29

* Applied changes from 2.3.1.
* [#173] Don't redirect to external URLs when `params[:redir_url]` is set.


## [3.0.0] - 2019-11-18

* Rename Room's and Server's #param to #slug.
* New route and logic to remove meeting objects.
* Remove `description` from meetings, move contents to `title`.
* Add option for users to edit the title of meetings.
* Send participant count in the ajax response when the meeting is running.
* Use incremental numbers when generating dial numbers, not random ones.
* Remove recordings when a meeting is removed.
* Add state to recordings, following new developments in BigBlueButton's API.
* Run the worker to fetch recordings after a meeting ends a little faster
  than before. Now that we track the state of recordings they will appear
  faster in a `getRecordings` call.
* Set the default title of new meetings to the name of the room.
* Add option to turn on debug on API calls.


## [2.3.1] - 2020-03-28

* [#168] No need to call end before a create anymore.
* [#171] Fix synchronization of unavailable recordings, would never mark them as available
  again if no other attribute changed.
* Prevent crashes if getRecordingToken fails.
* Add database indexes to speed up some queries.


## [2.3.0] - 2019-11-14

* [#136] Improve matching between recordings and meetings and migrate old recordings to
  always (when possible) have a meeting associated.
* Add new worker to fetch recordings after meetings are ended to improve the speed with which
  recordings are found after meetings
* Fix setting the `recorded` attributes in newly created meetings, it was always using the
  attributes from model, without considering that it is possible to override these attributes when
  making a "create" call (which is exactly what Mconf-Web does).
* First version of a JSON API that applications can use to list and join meetings created
  by this gem. All calls are authenticated by a secret configure in
  `BigbluebuttonRails.configuration.api_secret`.
* Remove old unnecessary json responses. Most routes had it but most were not used.
* Add docker configs to run the gem in development and to run tests.
* Set the `finish_time` on meetings when setting them as ended.
* Add options to set dynamic options when creating and joining conferences. See
  `get_create_options` and `get_join_options`.
* Make it easier for apps to customize the config.xml in a join call.
* Add support for `<recordingUsers>` returned by getRecordings.
* Add option to run on/off the authentication in playback URLs. When on, it will call
  `getRecordingToken` on the server holding the recording and use the proper parameters
  when redirecting the user to the playback URL.
  See `BigbluebuttonRails.configuration.playback_url_authentication`.
* Add option to show recording playback pages inside an iframe. Optional and off by default.
  If turned on all playback formats that are *not* downloadable will be shown inside an
  iframe. See `BigbluebuttonRails.configuration.playback_iframe`.
* Increase the limit in the name of rooms from 150 to 250 chars.
* Speed up recording sync by using batch imports (`activerecord-import`) and preventing
  unchanged recordings from being updated when syncing.
* Fix errors when trying to playback a recording that doesn't exist.


## [2.2.0] - 2017-10-04

* Make only description editable in recordings, since all other attributes are taken from
  the server and editing them won't change them in the server.
* Fix possible error when joining as guest but with permissions to create the room.
* Add action "check" to servers, redirects to the server's `/check`, an optional module in
  BigBlueButton.
* Remove db association between servers and rooms/meetings. Now servers are selected on the
  fly for a room that needs one. There's no association between them in the database anymore.
* Destroy recordings when their server is removed.
* Don't require `Server#url` and `Server#name` to be unique.
* Add `guest_support`, originally in Mconf-Web only. This feature is optional and disabled
  by default. Only works in Mconf-Live at this point (future feature on BigBlueButton).
* Fetch recordings of a server right after it is created.
* Improve how the gem is configured, add BigbluebuttonRails::Configuration. Makes it clearer
  how customizable variables and methods can be customized.
* Create a config for servers not in the db yet, so that we can fetch configs for servers
  not in the database.
* Update how the welcome message is set when there's a dial number set.
* Add helper methods to BigbluebuttonRecording. Used to calculate size and length of recordings.


## [2.1.0] - 2016-07-22

* [#98] Improved how meeting records are created and ended. Now they are more reliable and
  will work even if the resque workers are not running.
* [#132] Fixed recordings being set as unavailable when making requests to a subset of the
  recordings (when using filters in `getRecordings`).
* [#133] Added option for applications to pass custom metadata when a meeting is being
  created without having to create these metadata in the database.
* Renamed the attributes `BigbluebuttonServer#salt` to `BigbluebuttonServer#secret`.


------------------------------------

All tickets below use references to IDs in our old issue tracking system.
To find them, search for their description or ID in the new issue tracker.

------------------------------------


## [2.0.0] - 2016-04-07

To learn how to migrate to 2.0.0 see:
https://github.com/mconf/bigbluebutton_rails/wiki/Migrate-to-2.0.0

* New dependencies: `resque-scheduler` (to schedule background jobs).
* Dependencies removed: `whenever`.
* Updated the default ruby to 2.2.0.
* Updated to Rails 4, won't work with older versions.
* [#1637] Support for BigBlueButton 0.9 (includes all 0.9.x).
* Add 1.0 as a supported version of BigBlueButton.
* Drop support for BigBlueButton 0.7.
* [#827] Meeting "passwords" are now called "keys" to make it explicit that they
  are not real passwords.
* [#828] Meeting keys sent to API calls are now separate from the keys defined by
  the users. The ones defined by the users are used internally only; the
  ones sent in API calls are generated by the gem. Meeting keys now can be changed
  while a meeting is running without breaking API calls.
* [#722] Use the API parameter `createTime` in all `join` API calls to prevent
  URLs from being reused.
* [#722] Use the API parameter `userID` in all `join` API calls.
* [#1142, #1482] Improve the names for playback types, that now won't show up as the
  keys defined in BigBlueButton (e.g. `presentation`) but as a translated string defined
  in the locale files. Also added tooltips to explain what each playback format does.
* [#1140, #1141] Fetch and store default web conference configurations. The gem now keeps
  information related to the server's configurations (currently only the list of
  available layouts) so that this information can be used by the application. The information
  is updated automatically every hour or whenever a server is updated (e.g. a new salt is
  configured).
* [#1532] Fix join redirecting to the desktop client on tablets.
* [#1475] Fix issues when servers are removed and improve how a server is associated
  with a room, which is now more dynamic.
* [#915] Set recordings as unavailable only for the target server when synchronizing
  the recordings of the server. Previously it would set all recordings from other servers
  as unavailable.
* [#1571] Add localization of layout names.
* [#1616] Add the metadata `invitation-url` to create calls. Used to store the URL of
  a room in a recording's metadata.
* [#606] Always call `end` before creating a new meeting. This prevents a meeting create
  from failing after parameters changed (e.g. access key).
* [#1686, #1787] Automatically set the version number of a server (taken from the API) instead
  of requiring it to be specified manually.
* [#1703] Add option to set the background image of a conference room.
* [#1823] Include methods to help applications generate unique dial numbers.
* [#1707] Speed up tests, mostly by using the gem `webmock`.
* Join calls now use the parameter `createTime`. See
  http://docs.bigbluebutton.org/dev/api.html#join
* Rename `BigbluebuttonMeeting#record` to `#recorded` and `BigbluebuttonRoom#record`
  to `#record_meeting` to prevent conflicts with Rails.
* Add translation to pt-br.
* Add attribute `size` to recordings (currently on Mconf-Live only). Works
  even if the web conference server doesn't have it.
* Removed the name uniqueness requirement for a room, since this parameter is not
  necessarily unique in BigBlueButton.
* Don't generate voice bridges automatically, let the web conference server generate
  it. It's still possible to set custom voice bridges, but the gem will not generate
  them anymore.
* Show the dial number in the welcome message if there's a dial number set in the room.
* Set defaults for `auto_start_recording` and `allow_start_stop_recording` following the
  defaults in BigBlueButton.
* Accept HTTPS as the web conference server protocol.
* Fix setting `false` values in `config.xml` options.
* Fix room delegates to server when the server is nil.


## [1.4.0] - 2014-09-28

To learn how to migrate to 1.4.0 see:
https://github.com/mconf/bigbluebutton_rails/wiki/Migrate-to-1.4.0

* New dependencies:
  * resque: To keep track of meetings that happened.
  * strong_parameters: To allow controllers to decide which parameters can
    be modified and which can't. Default in Rails 4, should also be used
    in Rails 3.
* With strong_parameters in all controllers now the application can decide
  which parameters can be accessed and which can't. You can have different
  logics for different types of users.
* Use `params[:redir_url]` (if present) to redirect the user to a custom URL
  in all actions where possible. This can be set by the application to
  redirect the user to a custom location after updating a model, for
  instance.
* Register meetings that happened: new model `BigbluebuttonMeeting` that
  stores instances of meetings that happened in a room. Uses resque to
  monitor when meetings started. They are also associated with recordings,
  so the application can show a registry of meetings that happened and their
  respective recording.
* MySQL as a default database (was sqlite).
* First logic layout to set a custom config.xml when joining a room:
  * Every room has an associated BigbluebuttonRoomOptions model;
  * This model contains custom options that will be set in the config.xml
    when a user joins the associated room;
  * When the user joins, the library will get the default config.xml from
    the server, modify it according to the BigbluebuttonRoomOptions, and
    set it on the server to use it in the `join` API call;
  * Currently the only parameters that can be customized are: `default
    layout`, `presenter_share_only`, `auto_start_audio`, and
    `auto_start_video`.
* Fixed the mobile urls generated in `join_mobile`.
* Updated ruby to 1.9.3-p484.
* New controller method `bigbluebutton_create_options`. Can return a hash of
  parameters that will override the parameters in the database when sending
  a create call. Can be used to force some options when creating a meeting
  without needing to save it to the database.
* Removed the routes to join external rooms. This feature was never really
  used, so was just consuming space and time. Removed the actions
  `RoomsController#external` and `RoomsController#external_auth`. The flag
  `external` in `BigbluebuttonRoom` is still there, since it is used to
  identify external meetings when fetching the meetings from a server.
* New logic to join meetings from mobile devices: now there's no specific
  page to join from a mobile. Once /join is called, if the user is in a
  mobile device (detected using the user's "user-agent") then a page will be
  rendered and the user will be automatically redirected to the conference
  using the mobile client. This page has also more information just in case
  the user is not properly redirected (if the mobile client is not
  installed, for example).
* Removed the login via QR Code.

## [1.3.0] - 2013-07-27

To learn how to migrate to 1.3.0 see:
https://github.com/mconf/bigbluebutton_rails/wiki/Migrate-to-1.3.0

* New dependency:
  * whenever: To configure cron to trigger resque.
* Support for recordings. Details at
  https://github.com/mconf/bigbluebutton_rails/wiki/How-Recordings-Work.
  #459.
* Updated most of the dependencies to their latest version.
* Tested against Rails 3.2 (was Rails 3.0).
* New option `:as` in router helpers (more at
  https://github.com/mconf/bigbluebutton_rails/wiki/How-to%3A-Routes)
* New option `:only` in router helpers (more at
  https://github.com/mconf/bigbluebutton_rails/wiki/How-to%3A-Routes)
* Set the HTTP header `x-forwarded-for` with the IP of the client so servers
  can know who is creating/joining a meeting, for example.
* Removed assets (jquery, image) from the generator and from the gem.
* Removed the option to randomize meeting IDs, now they are fixed and
  generated as a globally unique meeting ID
  (`"#{SecureRandom.uuid}-#{Time.now.to_i}"`). #734, #735.
* Added logic to control who can create meetings (method called
  `bigbluebutton_can_create?`).

## [1.2.0] - 2012-05-04

* Updated ruby to 1.9.3-194.
* Support to BigBlueButton 0.8 rc1.
* Updated bigbluebutton-api-ruby to 1.1.0.

## [1.1.0] - 2012-05-04

* Rooms are now decoupled from servers:
  * A room can exist without a server;
  * Everytime a 'send_create' is called in a room, the method
    'select_server' is called to select a server where the meeting will be
    held. The room is saved if the server changed;
  * The method 'select_server' by default selects the server with less
    rooms;
  * The routes for rooms are not nested with servers anymore
    ('/bigbluebutton/rooms' instead of '/bigbluebutton/server/:id/rooms').
    * Because of this change all path helpers for rooms **must be
      updated!**
* rooms/external now receives a parameter "server_id" to indicate the server
  in which the external rooms is running. The views were updated.
* "bigbluebutton_routes :room_matchers" now generates all routes available
  for rooms, not only a selected set as before.

## [1.0.0] - 2012-05-04

* First version with support to BigBlueButton 0.8:
  * The support is still very basic: you can use the gem with BBB 0.8 but
    not all features are supported yet, such as pre-upload of slides and
    anything related to recordings.
  * Updated bigbluebutton-api-ruby to 0.1.0 to support BBB 0.8.
  * Added several integration tests.
* Several small bug fixes

## [0.0.6] - 2011-09-02

* After fetch_meetings, the rooms that are not found in the DB are **not**
  saved by default anymore.
* New action to join external rooms (rooms that are not in the DB but exist
  in the BBB server).
* Fixed some errors and warnings for Ruby 1.8.
* Some changes in the logic of RoomsController#auth to enable a user to join
  a room that has a blank password.
* Improvements in the mobile_join view to show a link that includes user
  authentication. But the QR code is still a bare link to the BBB server.
* Made some improvements based on tips by rails_best_practices and increased
  the test coverage to 100% for almost all classes.


## [0.0.5] - 2011-06-21

* URLs for both servers and rooms are now defined with a string attribute
  (called "param") instead of the model ID.
* New return values for bigbluebutton_role: :password and nil.
* Private rooms now require a password to be valid.
* New action "join_mobile" for rooms that renders a QR code to join the
  conference using the protocol "bigbluebutton://".
* New action "activity" for servers that shows a view to monitors a BBB
  server.
* Added json responses for most of the actions.
* logout_url can be an incomplete url and it will be completed with the
  current domain/protocol when a room is created in the BBB server.
* The generator bigbluebutton_rails:public was removed. It's features are
  now inside bigbluebutton_rails:install.
* After fetch_meetings all rooms are automatically stored in the DB if they
  are not there yet.

## [0.0.4] - 2011-05-16

* A random voice_bridge with 5 digits (recommended) is set when a room is
  created.
* Routes generators now allow specifying custom controllers instead of the
  defaults Bigbluebutton::ServersController and
  Bigbluebutton::RoomsController.
* Some bug fixes (including fixes for ruby 1.8).

## [0.0.3] - 2011-04-28

* Rooms can be public or private
* New route RoomsController#invite used to request a password to join a room
  or to allow anonymous users to join.
* Room's "meeting_id" attribute renamed to "meetingid".
* A room can have it's meetingid randomly generated for each "send_create"
  call if randomize_meetingid is set.
* New attributes for rooms: logout_url, dial_number, voice_bridge and
  max_participant.

## [0.0.2] - 2011-04-08

* New "fetch" and "send" methods in BigbluebuttonRooms to fetch info about
  meetings from BBB and store in the model.
* New class BigbluebuttonAttendee to store attendee information returned by
  BBB in get_meeting_info.
* New class BigbluebuttonMeeting to store meeting information returned by
  BBB in get_meetings.

## 0.0.1

* First version
* DB models for BigBlueButton servers and rooms
* Controller to access servers and rooms
* rooms_controller interacts with a BBB server using bigbluebutton-api-ruby

[3.2.0]: https://github.com/mconf/bigbluebutton_rails/compare/v3.1.2...v3.2.0
[3.1.2]: https://github.com/mconf/bigbluebutton_rails/compare/v3.1.1...v3.1.2
[3.1.1]: https://github.com/mconf/bigbluebutton_rails/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/mconf/bigbluebutton_rails/compare/v3.0.1...v3.1.0
[3.0.1]: https://github.com/mconf/bigbluebutton_rails/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/mconf/bigbluebutton_rails/compare/v2.3.1...v3.0.0
[2.3.1]: https://github.com/mconf/bigbluebutton_rails/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/mconf/bigbluebutton_rails/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/mconf/bigbluebutton_rails/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/mconf/bigbluebutton_rails/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/mconf/bigbluebutton_rails/compare/v1.4.0...v2.0.0
[1.4.0]: https://github.com/mconf/bigbluebutton_rails/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/mconf/bigbluebutton_rails/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/mconf/bigbluebutton_rails/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/mconf/bigbluebutton_rails/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mconf/bigbluebutton_rails/compare/v0.0.6...v1.0.0
[0.0.6]: https://github.com/mconf/bigbluebutton_rails/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/mconf/bigbluebutton_rails/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/mconf/bigbluebutton_rails/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/mconf/bigbluebutton_rails/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/mconf/bigbluebutton_rails/compare/v0.0.1...v0.0.2
