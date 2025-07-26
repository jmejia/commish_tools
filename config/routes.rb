Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
  }
  root 'home#index'

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Sleeper integration routes
  get '/connect_sleeper', to: 'leagues#connect_sleeper'
  post '/connect_sleeper', to: 'leagues#connect_sleeper_account'
  get '/select_sleeper_leagues', to: 'leagues#select_sleeper_leagues'
  post '/import_sleeper_league', to: 'leagues#import_sleeper_league'

  # Profile routes
  get '/profile', to: 'profile#show', as: :profile
  get '/profile/edit', to: 'profile#edit', as: :edit_profile
  patch '/profile', to: 'profile#update'

  # Main application routes
  resources :leagues do
    member do
      get :dashboard
    end

    resource :league_context, only: [:edit, :update], path: 'context'

    resources :league_memberships, only: [:create, :destroy] do
      resources :voice_clones, except: [:index] do
        resources :voice_upload_links, only: [:index, :new, :create, :destroy], path: 'upload_links'
      end
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

  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    resources :super_admins, only: [:index, :create, :destroy]
    resources :users, only: [:index, :show]
    resources :sleeper_connection_requests, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end
end
