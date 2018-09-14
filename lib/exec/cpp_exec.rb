require 'tmpdir'
require 'open3'
require "exceptions"
class CppExec

  def initialize(source, input)
    @source = source
    @input = input
    @output = ""
    # @memory = 0
  end


  def read_stdout(stream)
    until stream.eof? || @output.bytesize>=ENV["MAX_STDOUT"].to_i do
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

  def execute()
    dir = Dir.mktmpdir
    begin
      # use the directory...
      File.open("#{dir}/source.cpp", "w") do |file|
        file.puts(@source)
      end
      compile_error = ""
      Open3.popen2e("g++ -std=c++11  -o #{dir}/output.out #{dir}/source.cpp  ") do |stdin, stdout_and_stderr, wait_thr|
        while line=stdout_and_stderr.gets do
          compile_error << line
        end
      end

      if compile_error.present?
        compile_error = compile_error.gsub!("#{dir}/","")
        raise CompileTimeError, compile_error
      end

      # file = File.open("#{dir}/output.out", "rb")
      # contents = file.read
      # file.close
      # puts contents

      t1 = Time.now
      t2 = nil

      th1, th2 = nil
      stdin, stdout_stderr, wait_thr = Open3.popen2e("#{dir}/output.out")
      # th0 = Thread.new { track_memory_utilization(wait_thr) }
      begin
        timeout = ENV["EXECUTION_TIMEOUT"].present? ? ENV["EXECUTION_TIMEOUT"].to_i : 5
        Timeout.timeout(timeout) do
          begin
            th1 = Thread.new { read_stdout(stdout_stderr) }

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

          t2 = Time.now

        end
      rescue Timeout::Error
        puts 'process not finished in time, killing it'
        puts wait_thr.pid
        begin
          Process.kill("KILL",wait_thr.pid)
        rescue Errno::ESRCH => e
          puts "EXCEPTION: #{e.inspect}"
          puts "MESSAGE: #{e.message}"
        end
        raise RunTimeError, "Time limit exceeded (#{timeout}s)"
      ensure
        stdin.close if !stdin.closed?
        stdout_stderr.close
        # stderr.close if stderr
      end

      if wait_thr.value.signaled?

        run_error = "Runtime Error (#{Code::SIGN[wait_thr.value.termsig]})"
        raise RunTimeError, run_error
      else
        time,memory = 0,0
        Open3.popen3("/usr/bin/time -f \"%U %M\" #{dir}/output.out  ") do |stdin, stdout, stderr, wait_thr|
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
        exec_data = {output: @output, time: time, memory: memory}

        # exec_data = {output: @output, time: '%.4f' % (t2-t1), memory: @memory}
      end

    ensure
      # remove the directory.
      FileUtils.remove_entry dir
    end
    return exec_data
  end



end
