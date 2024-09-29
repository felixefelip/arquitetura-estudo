class Academico::Application::Aluno::Matricular::SuccessMailer < ApplicationMailer
  def send_mail(aluno)
    @mensagem = "
    Olá, #{aluno.nome}! Seu pagamento foi confirmado e sua matrícula foi criada com sucesso.
    Para acessar sua conta e começar a estudar conosco, acesse: http://localhost:4200/login.
    Seus dados de acesso são:
    E-mail: #{aluno.email}
    Senha: #{aluno.senha}
    Bons estudos!
    "

    mail to: aluno.email.to_s, subject: "Matrícula confirmada"
  end
end
