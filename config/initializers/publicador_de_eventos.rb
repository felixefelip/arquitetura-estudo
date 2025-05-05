Rails.application.config.after_initialize do
  $publicador = Shared::Domain::Evento::Publicador.new
  $publicador.adicionar_ouvinte(ouvinte: Academico::App::Aluno::MatriculadoOuvinte.new)
  $publicador.adicionar_ouvinte(ouvinte: Academico::Domain::Aluno::LogMatriculado.new)
  $publicador.adicionar_ouvinte(ouvinte: Marketing::Lead::ClientEnrolledListener.new)
end
