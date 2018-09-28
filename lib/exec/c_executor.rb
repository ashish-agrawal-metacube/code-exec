require 'tmpdir'
require "exceptions"
require "m_l_code_executor"
class CExecutor < MLCodeExecutor

  def execute
    dir = Dir.mktmpdir
    begin
      save_source_file("#{dir}/source.c")

      compile("gcc -std=c11 -o #{dir}/output.out #{dir}/source.c")
      if @compile_error.present?
        @compile_error.gsub!("#{dir}/","")
        raise CompileTimeError, @compile_error
      end

      run("#{dir}/output.out")
      if @run_error.present?
        raise RunTimeError, @run_error
      else
        time_and_memory("#{dir}/output.out")
      end

    ensure
      # remove temp directory.
      FileUtils.remove_entry dir
    end
  end

end
