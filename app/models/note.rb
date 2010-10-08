class Note < ActiveRecord::Base
  belongs_to :user

  def repo
    NoteRepository.find(:user_id=>user_id,:note_id=>id)
  end
  
  after_create :create_repo
  def create_repo
    NoteRepository.create(:user_id=>user_id,:note_id=>id)
  end

  after_destroy :destroy_repo
  def destroy_repo
    repo.destroy
  end

  module UserMethods
    def self.included(base)
      base.has_many :notes
    end
  end
end
