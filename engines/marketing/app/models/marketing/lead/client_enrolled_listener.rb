module Marketing
  module Lead
    class ClientEnrolledListener < ::Shared::Domain::Evento::Ouvinte
      #: (evento: Finance::Client::Enrolled) -> void
      def reage_ao(evento:)
        evento.client_payload.deep_symbolize_keys!

        messagem = "Lead com CPF #{evento.client_payload[:document]}
					                   foi convertido na data #{evento.momento}"

        Rails.logger.info messagem

        Convert.call(email: evento.client_payload[:email])
      end

      #: (evento: Finance::Client::Enrolled) -> bool
      def sabe_processar?(evento:)
        evento.name == "finance_client_enrolled"
      end
    end
  end
end
