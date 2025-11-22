class FormBuilder
  def initialize(model)
    @model = model
  end

  def input(field)
    value = @model.send(field)
    "<input name='#{field}' value='#{value}' />"
  end
end

module FormHelpers
  def self.form_for(model)
    builder = FormBuilder.new(model)
    yield builder
  end
end

FormHelpers.form_for(Marketing::Lead::Entity.new) do |form|
  form.input(:full_name)

	form.input(:email)
end
