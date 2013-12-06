# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'energy_market/version'
require 'date' # used for get Date.today 

Gem::Specification.new do |spec|
  spec.name          = "energy_market"
  spec.version       = EnergyMarket::VERSION
  spec.authors       = ["Iwan Buetti"]
  spec.email         = ["iwan.buetti@gmail.com"]
  spec.description   = "No description"
  spec.summary       = "Collection of classes used for energy (electricity and gas) market monitoring and calculation"
  spec.homepage      = "https://github.com/iwan/energy_market"
  spec.license       = "MIT"
  spec.date          = Date.today.to_s

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency('activesupport', '~> 3.2')
  spec.add_dependency('tzinfo', '~> 0.3.29') # '~> 1.1.0'
end
