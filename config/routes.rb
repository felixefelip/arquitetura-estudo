Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Rota raiz redireciona para página de compra
  root "marketing/leads#new"

  # Namespace Marketing
  namespace :marketing do
    resources :leads, only: [:new, :create] do
      collection do
        get :sucesso
      end
    end
  end

  # Namespace Academico
  namespace :academico do
    resources :alunos

    resources :cursos, only: [:index, :update] do
      member do
        patch :assistir
      end
    end

    resource :login, only: [:new, :create, :destroy]
  end

  # Namespace Finance
  namespace :finance do
    resources :clients, only: [:create]
  end
end
