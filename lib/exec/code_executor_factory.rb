require "exceptions"
class CodeExecutorFactory

  def self.for(lang,source,input)
    case lang
    when "gcc"
      CExecutor.new(source,input)
    when "g++"
      CppExecutor.new(source,input)
    when "java"
      JavaExecutor.new(source,input)
    else
      raise LangNotSupportedError, "Language not supported: #{lang}"
    end
  end

end
