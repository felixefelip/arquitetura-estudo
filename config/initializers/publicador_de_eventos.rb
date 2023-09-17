require_relative "../../app/models/shared/domain/evento/publicador"
require_relative "../../app/models/shared/domain/evento/ouvinte"
require_relative "../../app/models/academico/app/aluno/matriculado_ouvinte"

$publicador = Shared::Domain::Evento::Publicador.new
$publicador.adicionar_ouvinte(ouvinte: Academico::App::Aluno::MatriculadoOuvinte.new)
