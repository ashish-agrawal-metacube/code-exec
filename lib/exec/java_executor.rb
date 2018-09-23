require 'tmpdir'
require "exceptions"
require "v_m_code_executor"
class JavaExecutor < VMCodeExecutor


  CLASS_NOT_FOUND_MSG = "The program compiled successfully, but main class was not found.\nMain class should contain method: public static void main (String[] args).".freeze

  def execute
    dir = Dir.mktmpdir
    begin
      save_source_file("#{dir}/Main.java")

      Dir.mkdir "#{dir}/java"

      compile("javac -d #{dir}/java #{dir}/Main.java")
      if @compile_error.present?
        @compile_error.gsub!("#{dir}/","")
        raise CompileTimeError, @compile_error
      end

      exec_class = main_class
      puts "Main class"
      puts exec_class

      if main_class.empty?
        raise RunTimeError, CLASS_NOT_FOUND_MSG
      end

      run("java -classpath #{dir}/java #{exec_class}")
      if @run_error.present?
        raise RunTimeError, @run_error
      else
        time_and_memory("java -classpath #{dir}/java #{exec_class}")
      end

    ensure
      # remove temp directory.
      FileUtils.remove_entry dir
    end
  end

  private

  def main_class
    # remove all java comments
    @source.gsub! /((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))/, ""
    # remove all string literals
    @source.gsub! /((".+?")|('.+?'))/, ""
    # add a space before an after each keyword that we scan
    @source.gsub!(/[{}<>]|class|interface|public|main/) {|m| " #{m} "}

    tokens = @source.strip.split(/\s+/)
    main_class = ""
    current_class = ""
    stack = []
    i = 0; n = tokens.length
    while i<n
      case tokens[i]
      when "class","interface"
        if current_class.empty?
          current_class = tokens[i+1]
        else
          current_class = "#{current_class} #{tokens[i+1]}"
        end
        stack.push(current_class)
      when "{"
        stack.push("{")
      when "}"
        stack.pop
        top = stack.size-1
        if !("{}".include?(stack[top])) # top element is a class or interface
          current_class = stack[top].rpartition(' ').first
          stack.pop
        end
      when "public"
        if (i+3)<n && tokens[i+1]=="static" && tokens[i+2]=="void" && tokens[i+3]=="main"
          main_class = current_class.gsub(' ','$')
          break
          i = i + 3
        end
      end
      i = i+1
    end
    main_class.gsub!('$','\$') # escape linux character
    return main_class
  end


end
