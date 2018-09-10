# frozen_string_literal: true

Rails.application.routes.draw do
  get ":id-:story_title", to: "stories#show", constraints: {id: /\d{1,}/}

  root to: "stories#index"
end
