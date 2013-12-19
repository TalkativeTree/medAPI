class API::TermController < ApplicationController
  def search
    # @search = Search.matching_searches(tokens: tokens)
    @terms = Term.where(name: params[:term])
    respond_to do |format|
      format.html { render :nothing => true }
      format.json { render :json => {terms: @terms, results: params} }
    end
  end
end