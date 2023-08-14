FactoryBot.define do
  factory :bigbluebutton_room do |r|
    # meetingid with a random factor to avoid duplicated ids in consecutive test runs

    r.sequence(:meetingid) { |n| "meeting-#{n}-" + SecureRandom.hex(4) }

    r.sequence(:name) { |n| "Name#{n}" }
    r.attendee_key { Forgery(:basic).password :at_least => 10, :at_most => 16 }
    r.moderator_key { Forgery(:basic).password :at_least => 10, :at_most => 16 }
    r.attendee_api_password { SecureRandom.uuid }
    r.moderator_api_password { SecureRandom.uuid }
    r.welcome_msg { Forgery(:lorem_ipsum).sentences(2) }
    r.private { false }
    r.sequence(:slug) { |n| "meeting-#{n}" }
    r.external { false }
    r.record_meeting { false }
    r.duration { 0 }
    r.sequence(:voice_bridge) { |n| "7#{n.to_s.rjust(4, '0')}" }
    r.dial_number { SecureRandom.random_number(9999999).to_s }
    r.sequence(:logout_url) { |n| "http://bigbluebutton#{n}.test.com/logout" }
    r.sequence(:max_participants) { |n| n }

    after(:create) do |r|
      r.updated_at = r.updated_at.change(:usec => 0)
      r.created_at = r.created_at.change(:usec => 0)
    end

    factory :bigbluebutton_room_with_meetings do
      transient do
        last_meeting_create_time { nil }
        last_meeting_ended {false}
        last_meeting_running {true}
        meetings_count {1}
      end

      after(:create) do |room, evaluator|
        create_list(:bigbluebutton_meeting,
                    evaluator.meetings_count,
                    room: room)
        room.reload
        room.meetings.last.update(ended: evaluator.last_meeting_ended)

        # set random create_time for all meetings
        create_times = room.meetings.count.times.map do
          Time.now.to_i + rand(1_000..100_000)
        end
        sorted_create_times = create_times.sort
        room.meetings.each.with_index do |meeting, i|
          meeting.update(create_time: sorted_create_times[i])
        end

        if evaluator.last_meeting_create_time.present?
          room.meetings.last.update(create_time: evaluator.last_meeting_create_time)
        end

        if evaluator.last_meeting_ended
          time = Time.now.to_i
          room.meetings.last.update(finish_time: time,
                                    running: false,
                                    ended: true)
        elsif evaluator.last_meeting_running.present?
          room.meetings.last.update(running: evaluator.last_meeting_running)
        end
      end
    end

  end
end
