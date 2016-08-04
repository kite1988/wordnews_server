#require 'message_code.rb'

class AnnotationsController < ApplicationController
  
  # GET /annotations
  # GET /annotations.json
  def index
    @annotations = Annotation.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @annotations }
    end
  end

  # GET /annotations/1
  # GET /annotations/1.json
  def show
    @annotation = Annotation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation }
    end
  end
  
  
  def show_by_user_url
    if !params[:user_id].present? or !params[:url_postfix].present? or !params[:lang].present?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_INVALID_PARA}, 
                      status: :bad_request}
      end
      return
    end
    
    # obtain the article id
    article_id = get_article_id(params[:url_postfix], params[:lang])
    
    @annotations = article_id.nil? ? {}: Annotation.where('user_id=? AND article_id=?', params[:user_id], article_id)
      
    respond_to do |format|
      format.json { render json: {msg: Utilities::Message::MSG_OK, annotations: @annotations}, 
                    status: :ok}
    end
  end
  
  
  def show_by_url
    if !params[:url_postfix].present? or !params[:lang].present?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_INVALID_PARA}, 
                      status: :bad_request}
      end
      return
    end
    
    article_id = get_article_id(params[:url_postfix], params[:lang])
    @annotations = article_id.nil? ? {} : Annotation.where('article_id=?', article_id)
    
    respond_to do |format|
      format.json { render json: {msg: Utilities::Message::MSG_OK, annotations: @annotations}, 
                    status: :ok}
    end
  end
  
  
  def show_count_by_url
    if !params[:url_postfix].present? or !params[:lang].present?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_INVALID_PARA}, 
                      status: :bad_request}
      end
      return
    end
    
    count = Article.where('url_postfix=? AND lang=?', params[:url_postfix], params[:lang]).pluck(:annotation_count).first
    
    respond_to do |format|
      format.json { render json: {msg: Utilities::Message::MSG_OK, 
                    annotation_count: count}, status: :ok}      
    end
  end
  
  
  # TODO: Move to users_controller.rb?
  def show_user_annotation_history
    
    if !params[:user_id].present?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_INVALID_PARA}, 
                      status: :bad_request}
      end
      return
    end
      
      
    if params[:lang].present?
      sql = ['user_id=? and lang=?', params[:user_id], params[:lang]]
    else
      sql = ['user_id=?', params[:user_id]]
    end
    
    total_annotation = Annotation.count('id', :conditions=>sql)
    total_url = Annotation.count('article_id', :conditions=>sql, distinct: true)
    respond_to do |format|
      format.json { render json: {msg: Utilities::Message::MSG_OK, 
                    history: {annotation: total_annotation, url: total_url}},
                    status: :ok}
    end
   
  end
  
  # TODO: join the article table to obtain the full url
  # All the annotations done by a user
  # lang is optional
  def show_user_annotations    
    if !params[:user_id].present?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_INVALID_PARA}, 
                      status: :bad_request}
      end
      return
    end
    
    # invalid ID
    @user = User.find_by_id(params[:user_id])
    if @user.nil?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_NOT_FOUND}, 
                      status: :bad_request}
      end
      return
    end
      
    if params[:lang].present?
      @annotations = Annotation.where('user_id=? and lang=?', params[:user_id], params[:lang])
    else
      @annotations = Annotation.where('user_id=? ', params[:user_id])
    end
    respond_to do |format|
      format.html # show_user_annotations.html.erb
      format.json { render json: {msg: Utilities::Message::MSG_OK, annotations: @annotations}, 
                    status: :ok}
    end
  end
  
  
  # TODO: join the article table to obtain the full url
  # All the annotated urls done by a user
  # lang is optional
  def show_user_urls
    if !params[:user_id].present?
       respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_INVALID_PARA}, 
                      status: :bad_request}
      end
      return
    end

    @user = User.find_by_id(params[:user_id])
    if @user.nil?
      respond_to do |format|
        format.json { render json: {msg: Utilities::Message::MSG_NOT_FOUND}, 
                      status: :bad_request}
      end
      return
    end
    
    if params[:lang].present?
      @urls = Annotation.where('user_id=? and lang=?', params[:user_id], params[:lang]).uniq.pluck(:article_id)
    else
      @urls = Annotation.where('user_id=?', params[:user_id]).uniq.pluck(:article_id)
    end
    respond_to do |format|
      format.html # show_user_annotations.html.erb
      format.json { render json: {msg: Utilities::Message::MSG_OK, urls: @urls}, 
                    status: :ok}
    end
  end
  


  # GET /annotations/new
  # GET /annotations/new.json
  def new
    @annotation = Annotation.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @annotation }
    end
  end

  # GET /annotations/1/edit
  def edit
    @annotation = Annotation.find(params[:id])
  end

  # POST /annotations
  # POST /annotations.json
  def create
    
    # TODO: a better validation strategy (use strong parameter?)
    if (!params[:annotation].present? or !params[:annotation][:ann_id].present? \
        or !params[:annotation][:user_id].present? \
        or !params[:annotation][:selected_text].present? \
        or !params[:annotation][:translation].present? \
        or !params[:annotation][:lang].present?\
        or !params[:annotation][:paragraph_idx].present?\
        or !params[:annotation][:text_idx].present?\
        or !params[:annotation][:url].present? \
        or !params[:annotation][:url_postfix].present? \
        or !params[:annotation][:website].present?) 
      respond_to do |format|
        format.json { render json: { msg: Utilities::Message::MSG_INVALID_PARA }, 
                      status: :bad_request } 
      end
      return
    end
        
    # Obtain article or create if not exists
    article = get_or_create_article(
      params[:annotation][:url], params[:annotation][:url_postfix],
      params[:annotation][:lang], params[:annotation][:website])
      
    @annotation = Annotation.new(
      ann_id: params[:annotation][:ann_id], 
      user_id: params[:annotation][:user_id],
      selected_text: params[:annotation][:selected_text],
      translation: params[:annotation][:translation],
      lang: params[:annotation][:lang],
      paragraph_idx: params[:annotation][:paragraph_idx],
      text_idx: params[:annotation][:text_idx],
      article_id: article.id)
      
    Annotation.transaction do
      if @annotation.save and article.update_attribute(:annotation_count, article.annotation_count+1)
          respond_to do |format|
             format.json { render json: {msg: Utilities::Message::MSG_OK, id: @annotation.id}, status: :ok }
          end
      else
        respond_to do |format|
           format.json { render json: @annotation.errors, status: :bad_request }

        end
      end
    end
  end


  # PUT /annotations/1
  # PUT /annotations/1.json
  def update
    @annotation = Annotation.find(params[:id])

    respond_to do |format|
      if @annotation.update_attributes(params[:annotation])
        #format.html { redirect_to @annotation, notice: 'Annotation was successfully updated.' }
        format.json { head :no_content }
      else
        #format.html { render action: "edit" }
        format.json { render json: @annotation.errors, status: :unprocessable_entity }
      end
    end
  end
  
  
  def update_translation
    if !params[:id].present? or !params[:translation].present?
      respond_to do |format|
        format.json { render json: { msg: Utilities::Message::MSG_INVALID_PARA }, 
                      status: :bad_request } 
      end
      return
    end
    
    @annotation = Annotation.find_by_id(params[:id])
    if @annotation.nil?
      respond_to do |format|
        format.json { render json: { msg: Utilities::Message::MSG_NOT_FOUND}, 
                      status: :ok }
      end
      return
    end
    
    if @annotation.update_attribute(:translation, params[:translation])
      respond_to do |format|
        format.json { render json:{ msg: Utilities::Message::MSG_OK}, 
                      status: :ok}
      end
    else
      respond_to do |format|
        format.json { render json:{ msg: Utilities::Message::MSG_UPDATE_FAIL}, 
                      status: :ok} 
      end
    end
  end
    
    

  # DELETE /annotations/1
  # DELETE /annotations/1.json
  def destroy
    if !params[:id].present?
      respond_to do |format|
        format.json { render json: { msg: Utilities::Message::MSG_INVALID_PARA}, 
                        status: :bad_request }
      end
      return
    end
      
    @annotation = Annotation.find_by_id(params[:id])
    if @annotation.nil?
      respond_to do |format|
        format.json { render json: { msg: Utilities::Message::MSG_NOT_FOUND}, 
                      status: :ok }
      end
      return
    end
    
    article = Article.find_by_id(@annotation.article_id)
    if article.nil?
      respond_to do |format|
        format.json { render json: { msg: Utilities::Message::MSG_NOT_FOUND}, 
                      status: :ok }
      end
      return
    end
    
    Annotation.transaction do
      @annotation.destroy
      article.update_attribute(:annotation_count, article.annotation_count-1)
    end

    respond_to do |format|
      if @annotation.destroyed?
        format.json { render json: { msg: Utilities::Message::MSG_OK },
                      status: :ok}
      else
        format.json { render json: { msg: Utilities::Message::MSG_DELETE_FAIL },
                      status: :ok}
      end
    end
  end
  
    
  def get_or_create_article(url, url_postfix, lang, website)
    article = Article.where('url_postfix=? AND lang=?', url_postfix, lang).first

    if article.nil?
      article = Article.new(website: website, url: url, url_postfix: url_postfix, lang: lang, annotation_count: 0)
      article.save
    end
    return article
  end
  
  
  def get_article(url_postfix, lang)
    article = Article.where('url_postfix=? AND lang=?', url_postfix, lang).first
    return article
  end
  
  def get_article_id(url_postfix, lang)
    article_id = Article.where('url_postfix=? AND lang=?', url_postfix, lang).pluck(:id).first
    return article_id
  end
  
  
  #private
    #def validate_annotation
    #  params.require[:annotation].permits(:)
    #end
  #end
  
  
end






