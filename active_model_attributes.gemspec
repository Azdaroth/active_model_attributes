# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_model_attributes/version'

Gem::Specification.new do |spec|
  spec.name          = "active_model_attributes"
  spec.version       = ActiveModelAttributes::VERSION
  spec.authors       = ["Karol Galanciak"]
  spec.email         = ["karol.galanciak@gmail.com"]

  spec.summary       = %q{ActiveModel extension with support for ActiveRecord-like Attributes API}
  spec.description   = %q{ActiveModel extension with support for ActiveRecord-like Attributes API}
  spec.homepage      = "https://github.com/Azdaroth/active_model_attributes"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "coveralls"

  spec.add_dependency "activemodel", ">= 5.0"
  spec.add_dependency "activesupport", ">= 5.0"
end
