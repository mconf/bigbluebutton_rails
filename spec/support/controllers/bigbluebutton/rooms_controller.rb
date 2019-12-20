def build_running_json(value, qty, error=nil)
  if error.nil?
    hash = { :running => "#{value}", :meeting_info => qty }
  else
    hash = { :running => "#{value}"}
  end
  hash[:error] = error unless error.nil?
  hash.to_json
end


