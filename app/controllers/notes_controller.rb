class NotesController < ApplicationController
  before_filter :login_required,:except=>[:show]
  before_filter :per_load
  def per_load
    @note = Note.find(params[:note_id]) if params[:note_id]
  end

  def index
  end
  
  def new
  end

  def show
  end

  def create
    note = current_user.notes.create
    note.repo.edit_notefiles(params[:notefile])
    redirect_to show_note_path(:note_id=>note.id)
  end

  def edit
  end

  def update
    @note.repo.edit_notefiles(params[:notefile])
    redirect_to show_note_path(:note_id=>@note.id)
  end

  def destroy
    @note.destroy
    redirect_to "/"
  end

  def new_file
  end

end
