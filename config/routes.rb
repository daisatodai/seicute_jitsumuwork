# frozen_string_literal: true

Rails.application.routes.draw do
  post 'sessions/guest_login'
  post 'sessions/guest_admin_login'
  get 'searches/search'
  root 'invoices#index'
  resources :invoices, only: %w(new create index show edit update destroy)
  resources :requestors, only: %w(new create index edit update destroy) do
    collection do
      post :requestor_new
    end
  end
  resources :sessions, only: %w(new create destroy)
  resources :users, only: %w(new create index edit update destroy)
end