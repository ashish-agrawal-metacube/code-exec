require "exceptions"
class Code

  SIGN = { 1=> "SIGHUP",       2=> "SIGINT",       3=> "SIGQUIT",      4=> "SIGILL",
    5=> "SIGTRAP",      6=> "SIGABRT",      7=> "SIGBUS",       8=> "SIGFPE",
    9=> "SIGKILL",     10=> "SIGUSR1",     11=> "SIGSEGV",      12=>  "SIGUSR2",
    13=> "SIGPIPE",     14=> "SIGALRM",     15=> "SIGTERM",      16=> "SIGSTKFLT",
    17=> "SIGCHLD",     18=> "SIGCONT",     19=> "SIGSTOP",      20=> "SIGTSTP",
    21=> "SIGTTIN",     22=> "SIGTTOU",     23=> "SIGURG",       24=> "SIGXCPU",
    25=> "SIGXFSZ",     26=> "SIGVTALRM",   27=> "SIGPROF",      28=> "SIGWINCH",
    29=> "SIGIO",       30=> "SIGPWR",      31=> "SIGSYS",       3334=> "SIGRTMIN"
  }

  def self.execute(source,input,lang)
    case lang
    when "g++"
      c = CppExec.new(source,input)
    end
    begin
      result = c.execute()
    rescue CompileTimeError => error
      return { success:false, compile: false, compile_error: error }
    rescue RunTimeError => error
      return { success:false , compile: true, runtime_error: error }
    end

    {success:true, compile: true }.merge!(result)
  end

end
