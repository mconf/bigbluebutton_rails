module BigbluebuttonRailsHelper

  # Returns the URL for a QR-code image usign Google Charts API
  def qrcode_url(content, size=nil)
    size ||= "200x200"
    content = CGI::escape(content)
    "https://chart.googleapis.com/chart?cht=qr&chs=#{size}&chl=#{content}&choe=UTF-8"
  end

  # TODO: improve it, showing all flashes
  def bbb_rails_error_explanation
    if flash.key?(:error) and !flash[:error].blank?
      content_tag(:div, flash[:error], { :id => "error_explanation" })
    end
  end

end
