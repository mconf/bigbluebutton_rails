def build_running_json(value, error=nil)
  hash = { :running => "#{value}" }
  hash[:error] = error unless error.nil?
  hash.to_json
end


