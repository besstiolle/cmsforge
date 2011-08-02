class BugController < ApplicationController
  
  before_filter :authenticate_user!, :only => [ :add_comment, :add, :update ]
  
  def list
    @show_closed = (params[:show_closed] == 'true' || params[:show_closed] == '1')
    @conditions = @show_closed ? {} : {:state => 'Open'}
    params[:sort_by] ||= 'id ASC'

    @project_id = params[:id]
    @project = Project.find_by_id_and_state(@project_id, 'accepted')
    @bugs = @project.bugs.where(@conditions).paginate(:page => params[:page]).order(params[:sort_by])

    respond_to do |format|
      format.html { render }
      format.js { render :template => "bug/list.js.rjs" }
      format.xml { render :xml => @bugs.to_xml }
    end
  end
  
  def view
    @bug = Bug.find_by_id(params[:id])
    unless @bug.nil?
      @project = @bug.project
    end
    respond_to do |format|
      format.html { render }
      format.xml { render :xml => @bug.to_xml }
    end
  end
  
  def update
    @bug = Bug.find_by_id(params[:bug][:id])
    @project = @bug.project
    @bug.attributes = params[:bug]
    if @bug.valid?
      unless params[:add_comment].blank?
        comment = Comment.new
        comment.comment = params[:add_comment]
        comment.user = current_user
        @bug.comments << comment
      end
      @bug.save
      flash.now[:notice] = "Bug Succesfully Updated"
    end

    render :action => 'view' 
  end
  
  def add_comment
    bug = Bug.find_by_id(params[:bug_id])
    unless params[:add_comment].blank?
      comment = Comment.new
      comment.comment = params[:add_comment]
      comment.user = current_user
      bug.comments << comment
  
      #Kick off an update email
      bug.save
    end
    
    redirect_to :action => 'view', :id => bug.id
  end
  
  def add
    @bug = Bug.new(params[:bug])
    @bug.created_by = current_user
    @bug.project_id = params[:id] unless params[:id].nil?
  
    unless params[:cancel].nil?
      redirect_to :action => 'list', :id => @bug.project_id
      return
    end
  
    unless params[:bug].nil?
      if @bug.valid?
        @bug.state = 'Open'
        @bug.save
        redirect_to :action => 'list', :id => @bug.project_id
        return
      end
    end
  end
  
end
