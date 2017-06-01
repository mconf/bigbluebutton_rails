object false

child(@room => :data) {
  node(:type) { |obj| api_type_of(obj) }
  node(:id) { |obj| obj.to_param }

  node :attributes do |room|
    { :running => room.is_running? }
  end
}
