require 'erb'
[
  'node.rb',
  'trace_line.rb'
].each { |f| require File.expand_path("../#{f}", __FILE__) }

module WasTracer
  class Trace
    def initialize(file_name, parse_percent)
      @file_name = file_name
      @parse_percent = parse_percent
      File.open file_name, 'rb' do |f|
        @threads = parse f
      end
    end
  
    def parse(f)
      threads = {}
      current_line = 0
      methods_thread_map = {}
      node = nil

      progress = 0
      total_sz = f.stat.size
      $stderr.puts "Parsing..."
      f.each_line do |line_data|
        current_line += 1
        trace_line = TraceLine.from_line(line_data, current_line)
        unless trace_line
          node.more_data << line_data if node
          next
        end


        threadid = trace_line.thread_id


        methods_map = methods_thread_map[threadid] ||= {}
        node_stack = threads[threadid] ||= [Node.new(0)]


        current_parent = node_stack.last


        if trace_line.entering?
          node = Node.new(node_stack.size)
          node.entry_line = trace_line
          node.parent = current_parent
          (methods_map[trace_line.method_name] ||= []) << node
          current_parent.children << node
          node_stack << node
        elsif trace_line.exiting?
          next if node_stack.size == 1 # stack underflow skipping
          node = node_stack.last
        
          if node.entry_line.method_name != trace_line.method_name
            idx_parent = node_stack.reverse.index { |n| n.entry_line and n.entry_line.method_name == trace_line.method_name}
            if idx_parent
              #ignore nodes methods
              idx_parent.times do
                to_remove_node = node_stack.pop
                ignore_method(methods_map, to_remove_node.entry_line.method_name)
              end
            else
              #ignore trace_line method
              ignore_method(methods_map, trace_line.method_name)
              next
            end
          end
          node = node_stack.pop
          if node.entry_line.method_name != trace_line.method_name
            puts "\n\n\nStack Depth: #{node_stack.size}"
            puts "Method: #{node.entry_line.method_name} - Line: #{node.entry_line.line_number}"
            puts "Method: #{trace_line.method_name} - Line: #{trace_line.line_number}"
            raise "Invalid stack!\nEntry Line: #{node.entry_line.line}Exit Line : #{trace_line.line}"
          end
          node.exit_line = trace_line
        else
          node = Node.new(node_stack.size)
          node.entry_line = node.exit_line = trace_line
          current_parent.children << node
        end
      
        cur_bytes = f.tell
        new_progress = ((cur_bytes * 100) / total_sz)
        break if @parse_percent < 100 and new_progress >= @parse_percent
        if new_progress - progress >= 5
          $stderr.puts "%02d%%" % (progress = new_progress)
        end
      end
      $stderr.puts "Consolidating threads..."
      threads.merge!(threads) { |k, v| v.first }

      # removing incomplete nodes
      $stderr.puts "Removing incomplete nodes..."
      threads.each do |thread, root_node|
        root_node.children.delete_if do |node|
          node.exit_line.nil?
        end
      end
      threads
    end

    def ignore_method(methods_map, method_name)
      method_nodes = methods_map[method_name]
      method_nodes.reverse_each do |to_ignore_node|
        idx = to_ignore_node.parent.children.index(to_ignore_node)
        to_ignore_node.children.each { |n| n.parent = to_ignore_node.parent }
        parent_children = to_ignore_node.parent.children
        parent_children = parent_children[0...idx] + to_ignore_node.children + parent_children[(idx + 1)..-1]
        to_ignore_node.parent.children = parent_children
      end if method_nodes
      methods_map[method_name] = nil
    end

    def render_html(template)
      erb = ERB.new(File.read(template))
      erb.result(binding)
    end
  
    def render_html_frames(output_name)
      $stderr.puts "Rendering frames..."
      Dir.mkdir(output_name)
      write_template('frameset.html.erb', output_name, 'main')
      write_template('threads.html.erb', output_name, 'threads')
      @threads.each do |thread, root_node|
        next unless root_node.has_long_children?
        $stderr.puts "Rendering thread #{thread}..."
        @thread = thread
        @current_node = root_node
        write_template('one_thread.html.erb', output_name, "thread_#{thread}")
      end
      $stderr.puts "Done."
    end

    def render_template(template, cur_binding = binding)
      erb = ERB.new(File.read(File.expand_path("../template/#{template}", __FILE__)))
      erb.result(cur_binding)
    end

    def write_template(template, output_name, sufix)
      result = render_template(template, binding)
      File.open("#{output_name}/#{output_name}_#{sufix}.html", 'w') { |f| f.write(result) }
    end

    def render_children(node, template)
      return '' if node.children.size == 0
      @current_node = node
      render_template(template, binding)
    end
  end
end
