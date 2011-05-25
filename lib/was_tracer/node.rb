require 'cgi'

module WasTracer
  class Node
    attr_accessor :entry_line, :exit_line, :children, :level, :parent, :more_data

    def initialize(level)
      @children = []
      @level = level
      @more_data = []
    end

    def first_child
      @children.first
    end

    def last_child
      @children.last
    end

    def has_long_children?
      @children.any? { |c| c.duration > 0 }
    end

    def has_children?
      @children.size > 0
    end


    def each_long_children
      @children.each { |c| yield(c) if c.duration > 0 }
    end

    def duration
      @duration ||= exit_line.time - entry_line.time
    end

    def self_duration
      @self_duration ||= (duration - children_duration).abs
    end


    def duration_str
      '%07.3f' % duration
    end

    def self_duration_str
      '%07.3f' % self_duration
    end

    def children_duration
      @children.inject(0) { |s, child| s += child.duration }
    end

    def to_s
      entry_line.method_name
    end

    def has_details?
      entry_line != exit_line
    end

    def time
      has_details? ? "#{entry_line.time_str} - #{exit_line.time_str}" : entry_line.time_str
    end

    def lines_str
      has_details? ? "LINES: #{entry_line.line_number} - #{exit_line.line_number}" : "LINE: #{entry_line.line_number}"
    end

    def details
      det = lines_str
      det << " PARAMS: {#{entry_line.method_params}} - RETURN: {#{exit_line.method_params}}" if has_details?
      det
    end

    def more_details
      return "" if more_data.size == 0
      "<pre>" << more_data.inject("") { |total, data| total << CGI.escapeHTML(data) } << "</pre>"
    end

    def longer_child_duration
      return 0 if @children.size == 0
      @children.max { |c1, c2| c1.duration <=> c2.duration }.duration
    end
  end
end
