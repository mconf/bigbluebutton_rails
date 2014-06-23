module BigbluebuttonRailsHelper

  # Returns the URL for a QR-code image using Google Charts API
  def qrcode_url(content, size=nil)
    size ||= "200x200"
    content = CGI::escape(content)
    "https://chart.googleapis.com/chart?cht=qr&chs=#{size}&chl=#{content}&choe=UTF-8"
  end

  def bbb_rails_error_explanation
    msgs = ""
    flash.each do |key, msg|
      msgs += content_tag(:div, msg, { :id => "error_explanation", :class => key })
    end
    msgs.html_safe
  end

  # Setup a BigbluebuttonRoom to show in the forms
  def setup_bigbluebutton_room(room)
    (room.metadata.count..10).each { room.metadata.build }
    room
  end

  # Link to download the Android application from Google Play.
  def mobile_google_play_link
    "https://play.google.com/store/apps/details?id=air.com.mconf.mconfmobile"
  end

  # Google Play image to show together with the link to download the Android client.
  def mobile_google_play_image
    "badges/google_play_#{I18n.locale}.png"
  end

  # Link to download the iOS application from Apple Store.
  def mobile_apple_store_link
    "https://itunes.apple.com/us/app/mconf-mobile/id864391260"
  end

  # Apple Store image to show together with the link to download the iOS client.
  def mobile_apple_store_image
    "badges/apple_store_#{I18n.locale}.png"
  end

end
