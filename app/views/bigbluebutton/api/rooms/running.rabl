object @room => :data

node(:type) { |obj| obj.class.name }
node(:id) { |obj| obj.id.to_s }

node :attributes do |room|
  { :running => room.is_running? }
end
