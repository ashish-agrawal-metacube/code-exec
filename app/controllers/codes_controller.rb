class CodesController < ApplicationController


  def run

    # puts params[:source].dump
    # puts

    executor = CodeExecutorFactory.for(params[:lang],params[:source],params[:input])
    begin
      executor.execute
    rescue CompileTimeError => error
      render json: { success: false, compile: false, compile_error: error }, status: :ok ; return
    rescue RunTimeError => error
      render json: { success: false , compile: true, runtime_error: error }, status: :ok; return
    rescue LangNotSupportedError => error
      render json: { message: error }, status: :bad_request; return
    end

    render json: { success:true, compile: true, output: executor.output, time: executor.time, memory: executor.memory }, status: :ok
  end

end
