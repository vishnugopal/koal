# frozen_string_literal: true

Rails.application.routes.draw do
  get "/upload", to: "stories#new", as: :new_story
  post "/upload", to: "stories#create", as: :stories, :only => [:post]

  get ":id-:slug(/:chapter_order)", to: "stories#show", constraints: {id: /\d{1,}/},
                                    defaults: {chapter_order: 1}, as: :story

  %w(404 422 500 503).each do |code|
    get code, :to => "errors#show", :code => code
  end

  root to: "stories#index"
end
