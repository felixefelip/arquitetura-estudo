# rbs_inline: enabled

class Academico::LoginController < ApplicationController
  #: -> void
  def new
    render Academico::Login::NewComponent.new(error_message: flash[:alert])
  end

  #: -> void
  def create
    repo = Academico::Aluno::Repositories::ActiveRecord::Impl.new

    aluno = repo.buscar_por_email(params[:email])

    if aluno.present?
      # Armazena dados do usuário na sessão
      # session[:user_id] = aluno.id
      # session[:user_name] = aluno.nome
      # session[:user_email] = aluno.email

      redirect_to academico_cursos_path, notice: "Login realizado com sucesso!"
    else
      flash.now[:alert] = "Usuário e/ou senha inválidos"
      render Academico::Login::NewComponent.new(error_message: flash[:alert]), status: :unauthorized
    end
  end

  #: -> void
  def destroy
    session.delete(:user_id)
    session.delete(:user_name)
    session.delete(:user_email)

    redirect_to new_academico_login_path, notice: "Logout realizado com sucesso!"
  end
end
