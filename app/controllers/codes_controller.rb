class CodesController < ApplicationController


  def run

    puts params[:source].dump
    puts
    res = Code.execute(params[:source],params[:input],params[:lang])

    render json: res, status: :ok
  end

end
