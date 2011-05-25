# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "was_tracer/version"

Gem::Specification.new do |s|
  s.name        = "was_tracer"
  s.version     = WasTracer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Cezar Sá Espinola"]
  s.email       = ["cezarsa@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Websphere Application Server trace file visualizing tool.}
  s.description = %q{This gem allows you to parse IBM's Websphere Application Server trace files
containing methods entries and exits and outputs a set of HTML files that allows you to navigate
through a recreated call stack highlighting possible bottlenecks.}

  s.rubyforge_project = "was_tracer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
