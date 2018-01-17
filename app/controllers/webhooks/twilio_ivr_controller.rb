require 'twilio-ruby'

module Webhooks
  class TwilioIvrController < ::ActionController::API
    # NOTE: might want to validate with #find_call for menu_router just to be sure
    before_action :find_call, except: [:incoming_call, :menu_router]

    def incoming_call
      unless create_call
        render body: nil, status: 400 and return
      end

      message = "Listen to the following instructions, please. Press 1 to call the owner. Press 2 to leave a voicemail."
      gather = Twilio::TwiML::Gather.new(num_digits: '1', action: webhooks_twilio_menu_router_path)
      gather.say(message, voice: 'man', language: 'en-GB')
      call_response.append(gather)

      render xml: call_response.to_s
    end

    def menu_router
      case params[:Digits]
      when '1'
        redirect_call
      when '2'
        leave_voicemail
      when '*'
        call_response.hangup
      else
        twiml_say_and_redirect("Invalid option!")
      end
    end

    def incoming_voicemail
      @call.update_attributes(
        voicemail_url: params[:RecordingUrl],
        call_status:   params[:CallStatus]
      )

      render body: nil, status: 200
    end

    def status_callback
      @call.update_attributes(
        call_status: params[:CallStatus],
        call_duration: params[:CallDuration]
      )
      render body: nil, status: 200
    end

    def error
      @call.update_attribute(call_status: params[:CallStatus])
      render body: nil, status: 200
    end

    private

    def find_call
      unless params[:CallSid].nil?
        @call = Call.find_by(call_sid: params[:CallSid])
      end

      unless @call.present?
        render body: nil, status: 400 and return
      end
    end

    def create_call
      call_attrs = twilio_call_params.to_h.
                inject({}){ |memo,(k,v)| memo[k.underscore] = v; memo }
      @call = Call.new(call_attrs)
      @call.provider = 'twilio'
      @call.save
    end

    def twilio_call_params
      params.permit(
        :CallSid,
        :AccountSid,
        :From,
        :To,
        :CallStatus,
        :FromCity
      )
    end

    def twiml_say_and_redirect(phrase)
      call_response.say(phrase, voice: 'man', language: 'en-GB')
      call_response.redirect(webhooks_twilio_incoming_call_path)

      render xml: call_response.to_s
    end

    def redirect_call
      call_response.say('Please wait', voice: 'mail', language: 'en-GB')
      dial = Twilio::TwiML::Dial.new
      dial.number(ENV['PERSONAL_NUMBER'])
      call_response.append(dial)

      render xml: call_response.to_s
    end

    def leave_voicemail
      status = params[:DialCallStatus] || "completed"
      recording = params[:RecordingUrl]

      # If the call to the agent was not successful, or there is no recording,
      # then record a voicemail
      if (status != "completed" || recording.nil? )
        call_response.say("Please leave a message after the beep. End the call when finished",
            voice: 'man', language: 'en-GB')
        call_response.record(finish_on_key: "*", transcribe: true,
            transcribe_callback: webhooks_twilio_incoming_voicemail_path)
        call_response.say("I did not receive a recording.", voice: 'man', language: 'en-GB')
      # otherwise end the call
      else
        call_response.hangup
      end

      render xml: call_response.to_s
    end

    def call_response
      @call_response ||= Twilio::TwiML::VoiceResponse.new
    end
  end
end
