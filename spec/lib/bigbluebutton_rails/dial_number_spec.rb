require 'spec_helper'

describe BigbluebuttonRails::DialNumber do

  describe '#randomize' do
    context 'with no arguments informed' do
      it { BigbluebuttonRails::DialNumber.randomize.should be_nil }
    end

    context 'pattern "6xxx-xx"' do
      it { BigbluebuttonRails::DialNumber.randomize('6xxx-xx').should match(/^6\d\d\d-\d\d$/) }
    end

    context 'pattern "0AA-xAAA" and custom symbol "A"' do
      it {
        BigbluebuttonRails::DialNumber.randomize('0AA-xAAA', symbol: 'A').should match(/^\d\d\d-x\d\d\d$/)
      }
    end

    context 'pattern only with variables: "(xx) xxxx-xxxx"' do
      it {
        BigbluebuttonRails::DialNumber.randomize('(xx) xxxx-xxxx').should match(/^\(\d\d\) \d\d\d\d-\d\d\d\d$/)
      }
    end

    context 'pattern without variables: "(51) 1234"' do
      it {
        BigbluebuttonRails::DialNumber.randomize('(51) 1234').should eq("(51) 1234")
      }
    end
  end

  describe '#get_dial_number_from_ordinal' do
    let(:pattern) { '98xxxx-xxx'}
    let(:n1) { 34 }
    let(:n2) { 142 }
    let(:n3) { 2112 }

    it { BigbluebuttonRails::DialNumber.get_dial_number_from_ordinal(n1, pattern).should eq('980000-034') }
    it { BigbluebuttonRails::DialNumber.get_dial_number_from_ordinal(n2, pattern).should eq('980000-142') }
    it { BigbluebuttonRails::DialNumber.get_dial_number_from_ordinal(n3, pattern).should eq('980002-112') }

    context 'with pattern as nil' do
      it { BigbluebuttonRails::DialNumber.get_dial_number_from_ordinal(n1, nil).should eq(nil) }
      it { BigbluebuttonRails::DialNumber.get_dial_number_from_ordinal(n2, nil).should eq(nil) }
      it { BigbluebuttonRails::DialNumber.get_dial_number_from_ordinal(n3, nil).should eq(nil) }
    end
  end

  describe '#get_ordinal_from_dial_number' do
    let(:pattern) { '67xxx-xxx'}
    let(:n1) { '67000-001' }
    let(:n2) { '67001-001' }
    let(:n3) { '67123-321' }

    it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n1, pattern).should eq(1) }
    it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n2, pattern).should eq(1001) }
    it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n3, pattern).should eq(123321) }

    context 'with pattern as nil' do
      let(:pattern) { nil }

      it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n1, pattern).should eq(nil) }
      it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n2, pattern).should eq(nil) }
      it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n3, pattern).should eq(nil) }
    end

    context 'with a pattern that doesnt match the number' do
      let(:pattern) { '88xxx-xxx' }

      it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n1, pattern).should eq(nil) }
      it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n2, pattern).should eq(nil) }
      it { BigbluebuttonRails::DialNumber.get_ordinal_from_dial_number(n3, pattern).should eq(nil) }
    end

  end

end
