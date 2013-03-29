# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = %q{gimchi}
  gem.version       = "0.2.1"
  gem.authors       = ["Junegunn Choi"]
  gem.email         = ["junegunn.c@gmail.com"]
  gem.description   = %q{A Ruby gem for Korean characters}
  gem.summary       = %q{A Ruby gem for Korean characters}
  gem.homepage      = "https://github.com/junegunn/gimchi"

  gem.files         = `git ls-files`.split($/).reject { |f| f =~ %r[^viz/] }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license       = "MIT"

  gem.add_development_dependency 'ansi'
end
