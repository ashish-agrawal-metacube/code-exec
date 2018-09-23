require 'tmpdir'
require "exceptions"
require "m_l_code_executor"
class CppExecutor < MLCodeExecutor

  def execute
    dir = Dir.mktmpdir
    begin
      save_source_file("#{dir}/source.cpp")

      compile("g++ -std=c++11  -o #{dir}/output.out #{dir}/source.cpp")
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
