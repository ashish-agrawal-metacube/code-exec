class CodesController < ApplicationController


  def run

    res = Code.execute(params[:source],params[:input],params[:lang])

    render json: res, status: :ok
  end

end
