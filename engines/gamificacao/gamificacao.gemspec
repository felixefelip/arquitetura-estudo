require_relative "lib/gamificacao/version"

Gem::Specification.new do |spec|
  spec.name        = "gamificacao"
  spec.version     = Gamificacao::VERSION
  spec.authors     = ["Felipe Felix"]
  spec.email       = ["felipe.felix@maino.com.br"]
  spec.homepage    = "https://github.com"
  spec.summary     = "Summary of Gamificacao."
  spec.description = "Description of Gamificacao."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com"
  spec.metadata["changelog_uri"] = "https://github.com"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.6"
end
