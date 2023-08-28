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

  describe "#api_typeof" do
    it { api_type_of(FactoryBot.create(:bigbluebutton_room)).should eql('room') }
    it { api_type_of(FactoryBot.create(:bigbluebutton_server)).should eql('server') }
    it { api_type_of(FactoryBot.create(:bigbluebutton_recording)).should eql('recording') }

    context "for a new class" do
      class MyUserClass; end
      it { api_type_of(MyUserClass.new).should eql('my-user-class') }
    end
  end
end
