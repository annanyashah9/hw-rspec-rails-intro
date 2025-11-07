Rottenpotatoes::Application.routes.draw do
  resources :movies
  get '/search', to: 'movies#search_tmdb', as: 'search'
  post '/search_tmdb', to: 'movies#search_tmdb', as: 'search_tmdb'
  post '/add_movie', to: 'movies#add_movie', as: 'add_movie'
  root to: redirect('/movies')
end
