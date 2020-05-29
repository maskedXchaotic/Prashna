Rails.application.routes.draw do
  root 'welcome#index'

  resources :topic, only: [:index] do
    member do
      get 'questions'
    end
  end

  patch 'questions/:id', to: 'questions#draft_update', constraints: lambda {|r| r.params[:commit] == 'Draft' }
  patch 'questions/:id', to: 'questions#draft_publish_update', constraints: lambda {|r| r.params[:commit] == 'Publish' }

  resources :questions do
    collection do
      get 'drafts'
      get 'search'
    end
    member do
      get 'publish'
      get 'reaction'
      get 'report_abuse'
    end
    resources :comments,  only: [:new, :create]
    resources :answers,  only: [:new, :create]
  end
  
  resources :answers,  only: :show do
    member do
      get 'reaction'
      get 'report_abuse'
    end
    resources :comments,  only: [:new, :create]
  end
  
  
  resources :comments, only: [:new, :create, :show] do
    resources :comments, only: [:new, :create]
    member do
      get 'reaction'
      get 'report_abuse'
    end
  end

  get "my-profile", to: "users#current_user_profile"

  resources :users do
    resources :notifications, only: [:index]
    member do
      post :set_avatar
      post :set_topics
      get :questions
    end
  end

  controller :session do
    get 'login' => :new
    post 'login' => :create
    delete 'logout' => :destroy
  end

  get 'signup', to: "users#new"


  controller :password do
    get "forgot-password" => :forgot
    post 'find_user' => :find_user
    get "reset-password" => :reset
    patch "update-password" => :update
  end

  controller :users do
    get :verify
  end

  namespace :api do
    resources :feed, only: [:index]
    resources :topics, only: [:show]
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  mount LetterOpenerWeb::Engine, at: "/letter_opener"
end
