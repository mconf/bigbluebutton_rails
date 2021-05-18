require 'spec_helper'

module BigbluebuttonRails
  module Webhooks
    describe RapPublishEndedEvent do
      describe '.adapt_playback_format_to_api!' do
        let(:original_playback) do
          { format: 'presentation',
            link: 'https://localhost/playback/presentation/2.3/970b',
            duration: 2355,
            processing_time: 4060,
            extensions: {},
            size: 385_223 }
        end
        let(:modified_playback) { original_playback.clone }

        before do
          modified_playback[:format] = RapPublishEndedEvent.adapt_playback_format_to_api(modified_playback)
        end

        context 'should remove link and duraton keys' do
          it { expect(modified_playback.key?(:duration)).to be false }
          it { expect(modified_playback.key?(:link)).to be false }
        end

        context 'should keep every other key' do
          it do
            expect(original_playback.keys).to include(*modified_playback.keys)
          end
        end

        context 'new format should be a hash with :type, :url and :length' do
          it { expect(modified_playback.class).to be Hash }
          it do
            expect(modified_playback[:format][:type])
              .to eql original_playback[:format]
          end
          it do
            expect(modified_playback[:format][:length])
              .to eql original_playback[:duration]
          end
          it do
            expect(modified_playback[:format][:url])
              .to eql original_playback[:link]
          end
        end
      end
      describe '.adapt_to_api' do
        let(:attributes) {}
        let(:original_attributes) do
          {
            'meeting' => {
              'internal-meeting-id' => '0f0545e3084b65b2',
              'external-meeting-id' => 'random-951029'
            },
            'record-id' => '0f0545e3084b65b2',
            'success' => true,
            'step-time' => 1687,
            'workflow' => 'presentation',
            'recording' => {
              'name' => 'random-951029',
              'is-breakout' => 'false',
              'start-time' => 1_619_207_252_287,
              'end-time' => 1_619_207_267_324,
              'size' => 384_270,
              'raw-size' => 1_080_152,
              'metadata' => {
                'isBreakout' => 'false',
                'meetingId' => 'random-951029',
                'meetingName' => 'random-951029',
                'record' => 'true'
              },
              'playback' => {
                'format' => 'presentation',
                'link' => 'https://localhost/playback/presentation/2.3/0f05',
                'processing_time' => 9401,
                'duration' => 1616,
                'extensions' => {
                  'preview' => {}
                }, 'size' => 384_270
              }, 'download' => {}
            }
          }
        end

        let(:adapted_attributes) { RapPublishEndedEvent.adapt_to_api(original_attributes) }
        let(:recording) { original_attributes['recording'] }

        it do
          keys = %i[meetingid
                    recordid
                    name
                    start_time
                    end_time
                    size
                    published
                    metadata
                    playback
                    download].sort
          expect(adapted_attributes.keys.sort).to eql(keys)
        end
        it do
          expect(adapted_attributes[:meetingid])
            .to eql(original_attributes['meeting']['external-meeting-id'])
        end
        it do
          expect(adapted_attributes[:recordid])
            .to eql(original_attributes['record-id'])
        end
        it { expect(adapted_attributes[:name]).to eql(recording['name']) }
        it do
          expect(adapted_attributes[:start_time])
            .to eql(recording['start-time'])
        end
        it do
          expect(adapted_attributes[:end_time]).to eql(recording['end-time'])
        end
        it { expect(adapted_attributes[:size]).to eql(recording['size']) }
        it { expect(adapted_attributes[:published]).to be true }
        it do
          metadata = recording['metadata']&.symbolize_keys
          expect(adapted_attributes[:metadata]).to eql(metadata)
        end
        it do
          playback = recording['playback']&.symbolize_keys
          playback[:format] = RapPublishEndedEvent
                              .adapt_playback_format_to_api(playback)
          expect(adapted_attributes[:playback]).to eql(playback)
        end
        it do
          expect(adapted_attributes[:download])
            .to eql(recording['download']&.symbolize_keys)
        end
      end

      describe '.parse' do
        let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
        let(:server_id) { server.id }
        let(:event) do
          {
            'data' => {
              'type' => 'event',
              'id' => 'rap-publish-ended',
              'attributes' => {
                'meeting' => {
                  'internal-meeting-id' => '0f0545e',
                  'external-meeting-id' => 'random-951029'
                },
                'record-id' => '0f0545e',
                'success' => true,
                'step-time' => 1687,
                'workflow' => 'presentation',
                'recording' => {
                  'name' => 'random-951029',
                  'is-breakout' => 'false',
                  'start-time' => 1_619_207_252_287,
                  'end-time' => 1_619_207_267_324,
                  'size' => 384_270,
                  'raw-size' => 1_080_152,
                  'metadata' => {
                    'isBreakout' => 'false',
                    'meetingId' => 'random-951029',
                    'meetingName' => 'random-951029',
                    'record' => 'true'
                  },
                  'playback' => {
                    'format' => 'presentation',
                    'link' => 'https://localhost/playback/presentation/2.3/0f0545e',
                    'processing_time' => 9401,
                    'duration' => 1616,
                    'extensions' => {
                      'preview' => {}
                    },
                    'size' => 384_270
                  },
                  'download' => {}
                }
              }, 'event' => { 'ts' => 1_619_207_384 }
            }, server_id: server_id
          }
        end
        it do
          server = BigbluebuttonServer.find(server_id)
          attrs = RapPublishEndedEvent.adapt_to_api(event['data']['attributes'])
          expect(BigbluebuttonRecording).to receive(:sync).with(server, attrs, false)
          RapPublishEndedEvent.parse(event)
        end
      end
    end
  end
end
