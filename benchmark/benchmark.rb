$:.unshift File.expand_path('../../lib', __FILE__)

require "was_tracer"
require "fileutils"
require "benchmark"

tmp_name = 'tmp_dkjsady83hai'

t = nil
Benchmark.bmbm do |x|
  x.report("Parsing") {
    t = WasTracer::Trace.new(File.expand_path('../trace.log', __FILE__))
  }
  x.report("Rendering") {
    t.render_html_frames(tmp_name)
  }
end

FileUtils.rm_r "./#{tmp_name}", :force => true
