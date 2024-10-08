require_relative "../../app/models/shared/domain/evento/publicador"
require_relative "../../app/models/shared/domain/evento/ouvinte"
require_relative "../../engines/academico/app/models/academico/app/aluno/matriculado_ouvinte"
require_relative "../../engines/academico/app/models/academico/domain/aluno/log_matriculado"
require_relative "../../engines/marketing/app/models/marketing/lead/client_enrolled_listener"

$publicador = Shared::Domain::Evento::Publicador.new
$publicador.adicionar_ouvinte(ouvinte: Academico::App::Aluno::MatriculadoOuvinte.new)
$publicador.adicionar_ouvinte(ouvinte: Academico::Domain::Aluno::LogMatriculado.new)
$publicador.adicionar_ouvinte(ouvinte: Marketing::Lead::ClientEnrolledListener.new)
