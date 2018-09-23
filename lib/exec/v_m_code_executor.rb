class VMCodeExecutor < CodeExecutor


  def run(command)
    runtine_error = ""
    th1, th2, th3 = nil

    stdin, stdout, stderr, wait_thr = Open3.popen3(command,pgroup: true)

    begin
      timeout = ENV["EXECUTION_TIMEOUT"].present? ? ENV["EXECUTION_TIMEOUT"].to_i : 5
      Timeout.timeout(timeout) do
        begin
          th1 = Thread.new do
            while line=stderr.gets do
              runtine_error << line
            end
          end

          th2 = Thread.new { read_output(stdout) }

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
        pgid = Process.getpgid(wait_thr.pid)
        Process.kill("KILL",-pgid)
      rescue Errno::ESRCH => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
      end
      @run_error = "Time limit exceeded (#{timeout}s)"; return
    ensure
      stdin.close if !stdin.closed?
      stdout.close
      stderr.close
    end

    if !wait_thr.value.success?
      @run_error = runtine_error
    end

  end
end
