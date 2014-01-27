class BigbluebuttonRoomOptions < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  def get_available_layouts
    ["Default", "Video Chat", "Meeting", "Webinar", "Lecture assistant", "Lecture"]
  end

end
