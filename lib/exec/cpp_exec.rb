require 'tmpdir'
require 'open3'
require "exceptions"
class CppExec

  def initialize(source, input)
    @source = source
    @input = input
    @output = ""
  end


  def read_stdout(stream)
    until stream.eof? || @output.bytesize>=ENV["MAX_STDOUT"].to_i do
      @output << stream.readpartial(4096)
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
            # the real memory (resident set) size of the process (in kilobytes)
            # puts `ps -o rss= -p #{wait_thr.pid}`.chomp.to_i
            th1.join if th1.alive?

          rescue Errno::EPIPE
            puts "Connection broke!"
          rescue Exception => e
            puts "EXCEPTION: #{e.inspect}"
            puts "MESSAGE: #{e.message}"
          ensure
            stdin.close if !stdin.closed?
          end
          t2 = Time.now

        end
      rescue Timeout::Error
        puts 'process not finished in time, killing it'
        puts wait_thr.pid
        th1.kill if th1.alive?
        th2.kill if th2.present? && th2.alive?
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
        # time,memory = 0,0
        # Open3.popen3("/usr/bin/time -f \"%U %M\" #{dir}/output.out < #{dir}/input.in ") do |stdin, stdout, stderr, wait_thr|
        #   time,memory = stderr.gets.strip.split(" ")
        # end
        # time,memory = std_err[0].strip.split(" ")
      else

        exec_data = {output: @output, time: '%.4f' % (t2-t1), memory: 0}
      end

    ensure
      # remove the directory.
      FileUtils.remove_entry dir
    end
    return exec_data
  end



end
