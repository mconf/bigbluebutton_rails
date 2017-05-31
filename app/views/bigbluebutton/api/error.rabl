object false

node(:errors) do
  [
    { :status => "500",
      :title => @error.to_s,
      :detail => @error.to_s
    }
  ]
end
