class Academico::LoginController < ApplicationController
  def login
    repo = Academico::Aluno::Infra::Repositories::ActiveRecord::Impl.new

    aluno = repo.buscar_por_email(params[:email])

    if aluno.present?
      render json: { nome: aluno.nome, email: aluno.email }, status: :ok
    else
      render json: "Usuário ou senha inválidos", status: :unauthorized
    end
  end
end
