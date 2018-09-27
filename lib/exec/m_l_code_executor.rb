class MLCodeExecutor < CodeExecutor

  SIGN = { 1=> "SIGHUP",       2=> "SIGINT",       3=> "SIGQUIT",      4=> "SIGILL",
    5=> "SIGTRAP",      6=> "SIGABRT",      7=> "SIGBUS",       8=> "SIGFPE",
    9=> "SIGKILL",     10=> "SIGUSR1",     11=> "SIGSEGV",      12=>  "SIGUSR2",
    13=> "SIGPIPE",     14=> "SIGALRM",     15=> "SIGTERM",      16=> "SIGSTKFLT",
    17=> "SIGCHLD",     18=> "SIGCONT",     19=> "SIGSTOP",      20=> "SIGTSTP",
    21=> "SIGTTIN",     22=> "SIGTTOU",     23=> "SIGURG",       24=> "SIGXCPU",
    25=> "SIGXFSZ",     26=> "SIGVTALRM",   27=> "SIGPROF",      28=> "SIGWINCH",
    29=> "SIGIO",       30=> "SIGPWR",      31=> "SIGSYS",       3334=> "SIGRTMIN"
  }

  def run(command)
    th1, th2 = nil

    stdin, stdout_stderr, wait_thr = Open3.popen2e(command,pgroup: true) # add rlimit_nproc: [0, 0] to disable fork()

    begin
      timeout = ENV["EXECUTION_TIMEOUT"].present? ? ENV["EXECUTION_TIMEOUT"].to_i : 5
      Timeout.timeout(timeout) do
        begin
          th1 = Thread.new { read_output(stdout_stderr) }

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
        pgid = Process.getpgid(wait_thr.pid)
        Process.kill("KILL",-pgid)
      rescue Errno::ESRCH => e
        puts "EXCEPTION: #{e.inspect}"
        puts "MESSAGE: #{e.message}"
      end
      @run_error = "Time limit exceeded (#{timeout}s)"; return
    ensure
      stdin.close if !stdin.closed?
      stdout_stderr.close
    end

    if wait_thr.value.signaled?
      @run_error = "Runtime Error (#{SIGN[wait_thr.value.termsig]})"
    end

  end
end
