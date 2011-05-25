module WasTracer
  class TraceLine
    BASE_YEAR = 2000
    PARSE_REGEX = /
        \[(\d{1,2})\/(\d{1,2})\/(\d{2})\s # dd-mm-yy 1, 2, 3
        (\d{1,2}):(\d{1,2}):(\d{1,2}):(\d{3})\s # hh-mm-ss-uuu 4, 5, 6, 7
        \w{3}\]\s*
        ([\w]{8})\s* # threadid 8
        ([^\s]*)\s* # traceid 9
        (.)\s* # kind 10
        (.*)$ # data 11
    /x

    METHOD_REGEX = /
      ([^\s\(]*)\s* # class name 1
      (.*)\s* # method name 2
      (ENTRY|RETURN)\s*
      (.*)$ # params 4
    /x

    def self.from_line(line, line_number)
      match_group = line.chomp.match PARSE_REGEX
      TraceLine.new(match_group.captures, line, line_number) if match_group
    end

    attr_accessor :time, :time_str, :thread_id, :trace_name, :kind, :data, :line, :line_number

    def initialize(file_data, line, line_number)
      @time = Time.mktime(BASE_YEAR + file_data[2].to_i, file_data[0], file_data[1], 
                      file_data[3], file_data[4], file_data[5], file_data[6].to_i * 1000)
      @time_str = "#{file_data[3]}:#{file_data[4]}:#{file_data[5]}:#{file_data[6]}"
      @thread_id = file_data[7]
      @trace_name = file_data[8]
      @kind = file_data[9]
      @data = file_data[10]
      @line = line
      @line_number = line_number
    end

    def method_name
      return @data unless entering? or exiting?
      return @method_name if @method_name
      m = @data.match METHOD_REGEX
      @method_params = m[4]
      if m[2] =~ /^\(/
        @method_name = "#{m[1]}()"
      else
        @method_name = "#{m[1]}.#{m[2]}()"
      end
    end

    def method_params
      return '' unless entering? or exiting?
      return @method_params if @method_params
      m = @data.match METHOD_REGEX
      if m[2] =~ /^\(/
        @method_name = "#{m[1]}()"
      else
        @method_name = "#{m[1]}.#{m[2]}()"
      end
      @method_params = m[4]
    end


    def entering?
      @kind == '>'
    end

    def exiting?
      @kind == '<'
    end
  end
end