Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'dashboard#show'

  get 'dashboard', to: 'dashboard#show'

  namespace :webhooks do
    scope 'twilio/ivr' do
      post 'incoming_call',      to: 'twilio_ivr#incoming_call',      as: 'twilio_incoming_call'
      post 'incoming_voicemail', to: 'twilio_ivr#incoming_voicemail', as: 'twilio_incoming_voicemail'
      post 'menu_router',        to: 'twilio_ivr#menu_router',        as: 'twilio_menu_router'
      post 'status',             to: 'twilio_ivr#status_callback',    as: 'twilio_status_callback'
      post 'error',              to: 'twilio_ivr#error',              as: 'twilio_error'
    end
  end
end
