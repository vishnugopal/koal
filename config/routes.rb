# frozen_string_literal: true

Rails.application.routes.draw do
  get ":id-:slug(/:chapter)", to: "stories#show", constraints: {id: /\d{1,}/}, as: :story

  root to: "stories#index"
end
