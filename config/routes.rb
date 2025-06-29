Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  root 'home#index'

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Main application routes
  resources :leagues do
    member do
      get :dashboard
    end
    
    resources :league_memberships, only: [:create, :destroy] do
      resources :voice_clones, except: [:index]
    end
    
    resources :press_conferences do
      member do
        post :generate
        get :audio_player
      end
      
      resources :press_conference_questions, path: :questions
    end
  end

  # Voice upload routes (public access via token)
  get '/voice_uploads/:token', to: 'voice_uploads#show', as: :voice_upload
  post '/voice_uploads/:token', to: 'voice_uploads#create'
  
  # Audio streaming routes
  get '/audio/:id', to: 'audio#stream', as: :audio_stream
end
