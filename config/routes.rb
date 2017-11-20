Rails.application.routes.draw do
  resources :projects
  resources :posts
  resources :blogs

  match '/', to: 'blogs#index', constraints: { subdomain: 'www' }, via: [:get, :post, :put, :patch, :delete]
  match '/', to: 'blogs#show', constraints: { subdomain: /.+/ }, via: [:get, :post, :put, :patch, :delete]

  root to: "blogs#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
