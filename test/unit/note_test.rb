require 'test_helper'

class NoteTest < ActiveSupport::TestCase

  test "创建 删除 note" do
    repo_test do |lifei|
      assert_difference("Note.count",1) do
        note = lifei.notes.create
        assert File.exist?(note.repo.path)
      end

      note = Note.last
      assert_difference("Note.count",-1) do
        note.destroy
        assert !File.exist?(NoteRepository.repository_path(lifei.id,note.id))
      end
    end
  end

  test "增加内容" do
    repo_test do |lifei|
      
    end
  end

  def repo_test
    lifei = users(:repo_lifei)
    clear_user_repositories(lifei)
    yield lifei
    clear_user_repositories(lifei)
  end

  def clear_user_repositories(user)
    FileUtils.rm_rf(NoteRepository.user_repository_path(user.id))
    FileUtils.rm_rf(NoteRepository.user_recycle_path(user.id))
  end
  
end
