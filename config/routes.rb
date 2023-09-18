Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post "/login" => "academico/login#login"
  post "/cursos" => "academico/cursos#index"
  patch "/cursos/:id" => "academico/cursos#update"

  post "/leads" => "marketing/leads#create"
  post "/clients" => "finance/clients#create"

  namespace :academico do
    resources :alunos
  end
  resource :cursos, only: %i[update], controller: "academico/cursos"
end
