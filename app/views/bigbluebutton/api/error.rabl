object false

node(:errors) do
  @errors.map do |error|
    { :status => error.code.to_s,
      :title => error.title,
      :detail => error.to_s
    }
  end
end
