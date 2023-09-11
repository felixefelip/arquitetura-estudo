Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post "login" => "academico/login#login"
  get "cursos" => "academico/cursos#index"

  namespace :academico do
    resources :alunos
  end
  resource :cursos, only: %i[index update], controller: "academico/cursos"
end
