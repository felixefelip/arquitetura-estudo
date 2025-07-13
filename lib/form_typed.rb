class FormTyped
  def text_field(attribute:, klass:)
    "
			<input type='text' name='dose[#{attribute}]' class='#{klass}' value=''>
		"
  end

  # private

  # attr_accessor full_name: String
  # attr_accessor email: String
end


class User
end

# FormTyped.new(Marketing::Lead::Entity.new).text_field(attribute: FullName.new, klass: "form-control")
