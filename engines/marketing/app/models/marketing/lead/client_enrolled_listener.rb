module Marketing
  module Lead
    class ClientEnrolledListener
      def reage_ao(payload:)
        client_payload = payload.fetch(:client_payload)

        momento = payload.fetch(:momento)

        messagem = "Lead com CPF #{client_payload.fetch(:document)}
					                   foi convertido na data #{momento}"

        Rails.logger.info messagem

        Entity.convert(email: client_payload.fetch(:email))
      end
    end
  end
end
