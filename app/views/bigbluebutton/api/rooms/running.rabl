object false

child(@room => :data) {
  node(:type) { |obj| api_type_of(obj) }
  node(:id) { |obj| obj.id.to_s }

  node :attributes do |room|
    { :running => room.is_running? }
  end
}
