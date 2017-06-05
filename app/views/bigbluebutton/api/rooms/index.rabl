object false

node :links do
  @pagination_links
end

child @rooms, :root => :data, :object_root => false, :if => lambda { |r| @rooms.size > 0 } do
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
    url = polymorphic_path(owner)
    { :owner =>
      {
        :data => {
          :type => api_type_of(owner),
          :id => owner.to_param,
          :attributes => {
            :name => owner.try(:name)
          }
        },
        :links => {
          :self => url
        }
      }
    }
  end

  node :links do |room|
    { self: room.short_path }
  end
end

node :data, :if => lambda { |r| @rooms.size == 0 } do
  []
end
