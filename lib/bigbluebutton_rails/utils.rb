module BigbluebuttonRails

  # just a wrapper around the Rails method to convert values to boolean
  def self.value_to_boolean(value)
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end

end
