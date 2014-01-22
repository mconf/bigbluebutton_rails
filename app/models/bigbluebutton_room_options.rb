class BigbluebuttonRoomOptions < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :room, :class_name => 'BigbluebuttonRoom'

  def getAvailableLayouts
    ["Default","Meeting","Webinar"]
  end

end
