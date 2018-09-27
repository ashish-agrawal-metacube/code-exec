require 'open3'
class CodeExecutor

  def initialize(source, input)
    @source = source
    @input = input
    @output = ""
    @compile_error = nil
    @run_error = nil
    @time = 0
    @memory = 0
  end


  attr_reader :compile_error, :run_error, :output, :time, :memory

  # read output from given stream
  def read_output(stream)
    max_out = ENV["MAX_STDOUT"].present? ? ENV["MAX_STDOUT"].to_i : 2097152 # 2MB
    until stream.eof? || @output.bytesize>=max_out do
      @output << stream.readpartial(4096).force_encoding("ISO-8859-1").encode("UTF-8")
    end
  end

  def track_memory_utilization(thr)
    while thr.alive?
      # the real memory (resident set) size of the process (in kilobytes)
      mem = `ps -o rss= -p #{thr.pid}`.chomp.to_i
      if mem > @memory
        @memory = mem
      end
    end
  end

  # save source code file on at given path
  def save_source_file(path)
    File.open(path, "w") do |file|
      file.puts(@source)
    end
  end

  # compile source code
  def compile(command)
    compile_error = ""
    Open3.popen2e(command) do |stdin, stdout_and_stderr, wait_thr|
      while line=stdout_and_stderr.gets do
        compile_error << line
      end
    end
    @compile_error = compile_error
  end

  # find time (in seconds) and memory (in kilobytes) taken by code
  def time_and_memory(command)
    time,memory = 0,0
    th1 , th2 = nil
    Open3.popen3("/usr/bin/time -f \"%U %M\" #{command}  ") do |stdin, stdout, stderr, wait_thr|
      begin
        th1 = Thread.new do
          until stdout.eof? do
            stdout.readpartial(4096)
          end
        end

        if @input.present?
          input_lines = @input.split("\n")
          th2 = Thread.new do
            input_lines.each {|x| stdin.puts x }
          end
        end
        th2.join if th2.present?
        stdin.close
        th1.join

      rescue Errno::EPIPE
        puts "Connection broke!"
      rescue Exception => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
      ensure
        th2.kill if th2.present? && th2.alive?
        stdin.close if !stdin.closed?
        th1.kill if th1.alive?
      end

      time,memory = stderr.gets.strip.split(" ")
    end
    @time,@memory = time,memory
  end

end
