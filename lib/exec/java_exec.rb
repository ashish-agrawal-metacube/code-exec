require 'tmpdir'
require 'open3'
require "exceptions"
class JavaExec

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


  def execute()
    dir = Dir.mktmpdir
    begin
      # use the directory...
      File.open("#{dir}/Main.java", "w") do |file|
        file.puts(@source)
      end
      Dir.mkdir "#{dir}/java"

      compile_error = ""
      Open3.popen2e("javac -d #{dir}/java #{dir}/Main.java  ") do |stdin, stdout_and_stderr, wait_thr|
        while line=stdout_and_stderr.gets do
          compile_error << line
        end
      end

      if compile_error.present?
        compile_error = compile_error.gsub!("#{dir}/","")
        raise CompileTimeError, compile_error
      end

      success = false
      success_class = ""
      runtine_error = ""

      Dir["#{dir}/java/*.class"].sort!.each do |class_file|
        class_name = File.basename(class_file, '.class')
        
        th1, th2, th3 = nil

        stdin, stdout, stderr, wait_thr = Open3.popen3("java -classpath #{dir}/java #{class_name}")

        begin
          timeout = ENV["EXECUTION_TIMEOUT"].present? ? ENV["EXECUTION_TIMEOUT"].to_i : 5
          Timeout.timeout(timeout) do
            begin
              th1 = Thread.new do
                while line=stderr.gets do
                  runtine_error << line
                end
              end

              th2 = Thread.new { read_stdout(stdout) }

              if @input.present?
                input_lines = @input.split("\n")
                th3 = Thread.new do
                  input_lines.each {|x| stdin.puts x }
                end
              end
              th3.join if th3.present?
              stdin.close

              th1.join
              th2.join

            rescue Errno::EPIPE
              puts "Connection broke!"
            rescue Exception => e
              puts "EXCEPTION: #{e.inspect}"
              puts "MESSAGE: #{e.message}"
            ensure
              th3.kill if th3.present? && th3.alive?
              stdin.close if !stdin.closed?
              th1.kill if th1.alive?
              th2.kill if th2.alive?
            end

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
          stdout.close
          stderr.close
        end

        if wait_thr.value.success?
          success = true
          success_class = class_name
          break
        else
          if runtine_error.start_with?("Error: Main method not found")
            @output = ""
            runtine_error = ""
          else
            break
          end
        end

      end

      if !success
        if runtine_error.present?
          raise RunTimeError, runtine_error
        else
          raise RunTimeError, "The program compiled successfully, but main class was not found.\nMain class should contain method: public static void main (String[] args)."
        end
      else
        time,memory = 0,0
        Open3.popen3("/usr/bin/time -f \"%U %M\" java -classpath #{dir}/java #{success_class} ") do |stdin, stdout, stderr, wait_thr|
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
      end

    ensure
      # remove temp directory.
      FileUtils.remove_entry dir
    end
    return exec_data
  end




end
