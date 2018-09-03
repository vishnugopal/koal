# frozen_string_literal: true

Rails.application.routes.draw do
  resources :chapters
  resources :stories
  resources :authors

  root to: 'stories#index'
end
