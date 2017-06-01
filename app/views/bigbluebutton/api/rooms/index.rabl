collection @rooms => :data

node(:type) { |obj| api_type_of(obj) }
node(:id) { |obj| obj.id.to_s }

node :attributes do |room|
  attrs = { :identifier => room.param }
  [ :meetingid, :name, :attendee_key, :moderator_key, :welcome_msg, :logout_url,
    :voice_bridge, :dial_number, :max_participants, :private ].each { |attr|
    attrs.merge!({ :"#{attr}" => room.send(attr) })
  }
  attrs
end

node :relationships, :unless => lambda { |r| r.owner.nil? } do |room|
  owner = room.owner
  url = if owner.is_a?(Space)
          space_path(owner)
        elsif owner.is_a?(User)
          user_path(owner)
        else
          nil
        end
  { :owner =>
    {
      :links => {
        :self => url
      },
      :data => {
        :type => api_type_of(owner),
        :id => owner.id.to_s,
        :attributes => {
          :name => owner.name
        }
      }
    }
  }
end
