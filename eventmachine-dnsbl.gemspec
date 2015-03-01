# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eventmachine/dnsbl/version'

Gem::Specification.new do |spec|
  spec.name          = "eventmachine-dnsbl"
  spec.version       = EventMachine::DNSBL::VERSION
  spec.authors       = ["chrislee35"]
  spec.email         = ["rubygems@chrislee.dhs.org"]
  spec.summary       = %q{EventMachine-based implementation of DNSBL checker and server}
  spec.description   = %q{For use in the Rubot Emulation Framework, I needed an EventMachine-based implementation of a DNSBL checker and server.}
  spec.homepage      = "https://github.com/chrislee35/eventmachine-dnsbl"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "eventmachine", ">= 0.12.10"
  spec.add_runtime_dependency "sqlite3", ">= 1.3.6"
  spec.add_development_dependency "minitest", "~> 5.5"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
