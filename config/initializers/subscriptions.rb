Rails.application.config.after_initialize do
  # Registrando ouvintes para eventos com ActiveSupport::Notifications

  # Ouvinte para finance_client_enrolled
  ActiveSupport::Notifications.subscribe("finance_client_enrolled") do |_name, _start, _finish, _id, payload|
    listener = Academico::Aluno::MatriculadoOuvinte.new
    listener.reage_ao(payload: payload)
  end

  # Ouvinte para finance_client_enrolled (Marketing)
  ActiveSupport::Notifications.subscribe("finance_client_enrolled") do |_name, _start, _finish, _id, payload|
    listener = Marketing::Lead::ClientEnrolledListener.new
    listener.reage_ao(payload: payload)
  end

  # Ouvinte para aluno_matriculado
  ActiveSupport::Notifications.subscribe("aluno_matriculado") do |_name, _start, _finish, _id, payload|
    listener = Academico::Aluno::LogMatriculado.new
    listener.reage_ao(payload: payload)
  end
end
