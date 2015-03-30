require 'spec_helper'

describe BigbluebuttonRails do

  describe '.use_mobile_client?' do
    before do
      @browser = double
      BigbluebuttonRails.stub(:browser).and_return(@browser)
    end

    context 'for a mobile device' do
      before do
        @browser.stub(:mobile?).and_return(true)
        @browser.stub(:tablet?).and_return(false)
      end
      it { BigbluebuttonRails.use_mobile_client?(@browser).should be(true) }
    end

    context 'for a tablet' do
      before do
        @browser.stub(:mobile?).and_return(false)
        @browser.stub(:tablet?).and_return(true)
      end
      it { BigbluebuttonRails.use_mobile_client?(@browser).should be(true) }
    end

    context 'not a mobile device nor tablet' do
      before do
        @browser.stub(:mobile?).and_return(false)
        @browser.stub(:tablet?).and_return(false)
      end
      it { BigbluebuttonRails.use_mobile_client?(@browser).should be(false) }
    end

    # some user-agents where errors happened in the past
    context 'user-agents' do
      it {
        browser = Browser.new(ua: 'Mozilla/5.0 (iPad; CPU OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B466 Safari/600.1.4', accept_language: 'en-us')
        BigbluebuttonRails.use_mobile_client?(browser).should be(true)
      }
    end
  end

  describe '.value_to_boolean' do
    it { BigbluebuttonRails.value_to_boolean('true').should be(true) }
    it { BigbluebuttonRails.value_to_boolean('1').should be(true) }
    it { BigbluebuttonRails.value_to_boolean(1).should be(true) }
    it { BigbluebuttonRails.value_to_boolean(true).should be(true) }
    it { BigbluebuttonRails.value_to_boolean('t').should be(true) }
    it { BigbluebuttonRails.value_to_boolean('false').should be(false) }
    it { BigbluebuttonRails.value_to_boolean('0').should be(false) }
    it { BigbluebuttonRails.value_to_boolean(0).should be(false) }
    it { BigbluebuttonRails.value_to_boolean(false).should be(false) }
    it { BigbluebuttonRails.value_to_boolean('f').should be(false) }
  end
end
