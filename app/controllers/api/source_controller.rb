class API::SourceController < ApplicationController
  def search
    @source = Source.where(name: params[:name])
    respond_to do |format|
      format.html { render @source }
      format.json { render :json => @source }
    end
  end
end