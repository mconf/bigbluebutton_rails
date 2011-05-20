require 'spec_helper'

describe BigbluebuttonRailsHelper do

  describe "#qrcode_url" do
    let(:url) { "http://www.google.com" }
    let(:size) { "55x55" }

    subject { qrcode_url(url, size) }

    it("uses google charts api") { should match /https:\/\/chart.googleapis.com\/chart\?cht=qr/ }
    it("uses encoded content") { should match /chl=#{CGI::escape(url)}/ }
    it("uses size") { should match /chs=#{size}/ }
    it("uses UTF-8") { should match /choe=UTF-8/ }
  end

end


