require "rbs_infer"

def resolve_infer_args(input)
  source_files = Dir["app/**/*.rb", "engines/**/*.rb", "lib/**/*.rb"]

  if input.include?("/") || input.end_with?(".rb")
    { target_file: input, source_files: source_files }
  else
    { target_class: input, source_files: source_files }
  end
end

namespace :rbs do
  desc "Infer RBS types from call-site usage analysis (Prism-based)"
  task :infer, [:target] => :environment do |_t, args|
    target = args[:target]

    unless target
      puts "Uso: rake rbs:infer[Finance::Client::Enroll]"
      puts "     rake rbs:infer[engines/finance/app/models/finance/client/enroll.rb]"
      exit 1
    end

    analyzer = RbsInfer::Analyzer.new(**resolve_infer_args(target))
    rbs = analyzer.generate_rbs

    if rbs
      puts rbs
    else
      puts "Classe não encontrada ou nenhum membro detectado."
    end
  end

  desc "Infer RBS and write to sig/ directory"
  task :infer_write, [:target] => :environment do |_t, args|
    target = args[:target]

    unless target
      puts "Uso: rake rbs:infer_write[Finance::Client::Enroll]"
      puts "     rake rbs:infer_write[engines/finance/app/models/finance/client/enroll.rb]"
      exit 1
    end

    analyzer = RbsInfer::Analyzer.new(**resolve_infer_args(target))
    rbs = analyzer.generate_rbs

    if rbs
      class_name = analyzer.target_class
      path_parts = class_name.split("::").map { |p| p.gsub(/([a-z])([A-Z])/, '\1_\2').downcase }
      output_path = File.join("sig", "generated", *path_parts) + ".rbs"

      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, rbs + "\n")
      puts "RBS escrito em: #{output_path}"
      puts rbs
    else
      puts "Classe não encontrada ou nenhum membro detectado."
    end
  end
end
