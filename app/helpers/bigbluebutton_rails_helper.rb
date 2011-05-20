module BigbluebuttonRailsHelper

  # Returns the URL for a QR-code image usign Google Charts API
  def qrcode_url(content, size=nil)
    size ||= "200x200"
    content = CGI::escape(content)
    "https://chart.googleapis.com/chart?cht=qr&chs=#{size}&chl=#{content}&choe=UTF-8"
  end

end


