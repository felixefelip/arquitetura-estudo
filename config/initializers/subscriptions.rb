# Rails.application.config.after_initialize do
#   subscriptions = [
#     { class_name: "Academico::App::Aluno::MatriculadoOuvinte",
#       event_name: :finance_client_enrolled },
#     { class_name: "Academico::Domain::Aluno::LogMatriculado",
#       event_name: :aluno_matriculado },
#     { class_name: "Marketing::Lead::ClientEnrolledListener",
#       event_name: :finance_client_enrolled },
#   ]

#   subscriptions.each do |subscription|
#     ActiveSupport::Notifications.subscribe(subscription[:event_name], subscription[:class_name].constantize.new)
#   end
# end
