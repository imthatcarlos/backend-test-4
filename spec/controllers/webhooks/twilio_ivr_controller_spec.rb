require 'rails_helper'
require 'twilio-ruby'

describe Webhooks::TwilioIvrController do
  describe 'POST /twilio/ivr/incoming_call' do
    context 'with invalid Twilio Call params' do
      before { post :incoming_call, params: {CallSid: nil, From: nil, To: nil}}

      it 'returns a 400 status code' do
        expect(response.status).to eq 400
      end
    end

    context 'with valid Twilio Call params' do
      let(:twilio_params) {
        {
          CallSid: '123',
          AccountSid: '123',
          From: '123456789',
          To: '987654321',
          CallStatus: 'in-progress'
        }
      }

      it 'creates a Call record' do
        post :incoming_call, params: twilio_params
        expect(Call.count).to eq 1
      end
    end
  end

  describe 'POST /twilio/ivr/menu_router' do
    context 'with invalid Digits param' do
      it 'calls redirect on VoiceResponse and returns 200' do
        expect_any_instance_of(Twilio::TwiML::VoiceResponse).to receive(:redirect)
        post :menu_router, params: { Digits: nil }
        expect(response.status).to eq 200
      end
    end

    context 'with Digits param set to 1' do
      it 'creates an instance of Dial and dials personal number' do
        expect_any_instance_of(Twilio::TwiML::Dial).to receive(:number)
        post :menu_router, params: { Digits: 1 }
        expect(response.status).to eq 200
      end
    end

    context 'with Digits param set to 2' do
      it 'calls record on VoiceResponse and returns 200' do
        expect_any_instance_of(Twilio::TwiML::VoiceResponse).to receive(:record)
        post :menu_router, params: { Digits: 2 }
        expect(response.status).to eq 200
      end
    end
  end

  describe 'POST /twilio/ivr/incoming_voicemail' do
    context 'with invalid CallSid param' do
      let(:valid_record) { Fabricate(:call, call_sid: '123') }
      before { valid_record }

      it 'returns 400' do
        post :incoming_voicemail, params: { CallSid: '000' }
        expect(response.status).to eq 400
      end
    end

    context 'with valid CallSid param' do
      let(:valid_record) { Fabricate(:call, call_sid: '123') }
      before { valid_record }

      it 'updates the record with the RecordingUrl and returns 200' do
        post :incoming_voicemail, params: {
          CallSid:      valid_record.call_sid,
          RecordingUrl: 'audio_url',
          CallStatus:   'completed'
        }
        expect(Call.first.voicemail_url).to eq 'audio_url'
        expect(response.status).to eq 200
      end
    end
  end

  describe 'POST /twilio/ivr/status_callback' do
    context 'with invalid CallSid param' do
      let(:valid_record) { Fabricate(:call, call_sid: '123') }
      before { valid_record }

      it 'returns 400' do
        post :status_callback, params: { CallSid: '000' }
        expect(response.status).to eq 400
      end
    end

    context 'with valid CallSid param' do
      let(:valid_record) { Fabricate(:call, call_sid: '123')}
      before { valid_record }

      it 'updates the record with the new status and returns 200' do
        post :status_callback, params: {
          CallSid:      valid_record.call_sid,
          CallStatus:   'some-random-status'
        }
        expect(Call.first.call_status).to eq 'some-random-status'
        expect(response.status).to eq 200
      end
    end
  end
end
