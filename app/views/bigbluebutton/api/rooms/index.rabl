object false

child(@rooms => :data) do
  node(:type) { |obj| api_type_of(obj) }
  node(:id) { |obj| obj.to_param }

  node :attributes do |room|
    attrs = { }
    [ :name, :private ].each { |attr|
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
        :data => {
          :type => api_type_of(owner),
          :id => owner.to_param,
          :attributes => {
            :name => owner.name
          }
        },
        :links => {
          :self => url
        }
      }
    }
  end

  node :links do |room|
    { self: join_webconf_path(room) }
  end
end

node :links do
  @pagination_links
end
