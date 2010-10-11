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

  test "编辑内容" do
    repo_test do |lifei|
      note = lifei.notes.create
      assert_equal note.repo.text_hash.keys.count,0
      assert_equal note.repo.notefile_count,0
      # 编辑内容
      text_1 = "我是第一个片段"
      text_hash_1 = {"#{NoteRepository::NOTE_FILE_PREFIX}1"=>text_1}
      note.repo.replace_notefiles(text_hash_1)
      assert_equal note.repo.text_hash.keys.count,1
      assert_equal note.repo.notefile_count,1
      assert_equal note.repo.text_hash,text_hash_1
      sleep 1
      # 再次编辑内容
      text_2 = "我是第二个片段"
      text_3 = "我是第三个片段"
      text_hash_2 = {"#{NoteRepository::NOTE_FILE_PREFIX}1"=>text_1,
        "#{NoteRepository::NOTE_FILE_PREFIX}2"=>text_2,
        "#{NoteRepository::NOTE_FILE_PREFIX}3"=>text_3
      }
      note.repo.replace_notefiles(text_hash_2)
      assert_equal note.repo.text_hash.keys.count,3
      assert_equal note.repo.notefile_count,3
      assert_equal note.repo.text_hash,text_hash_2

      # 编辑内容
      sleep 1
      edit_text_1 = "修改第一个片段"
      text_hash_3 = {"#{NoteRepository::NOTE_FILE_PREFIX}1"=>edit_text_1,
        "#{NoteRepository::NOTE_FILE_PREFIX}3"=>text_3
      }
      note.repo.replace_notefiles(text_hash_3)
      assert_equal note.repo.text_hash.keys.count,2
      assert_equal note.repo.notefile_count,2
      assert_equal note.repo.text_hash,text_hash_3

      # 版本快照
      text_hash_array = note.repo.commit_ids.map do |id|
        note.repo.text_hash(id)
      end
      assert_equal text_hash_array.count,3
      # 最新的版本
      assert_equal text_hash_array[0].count,2
      assert_equal text_hash_array[0],text_hash_3
      # 倒数第二个版本
      assert_equal text_hash_array[1].count,3
      assert_equal text_hash_array[1],text_hash_2
      # 第一个版本
      assert_equal text_hash_array[2].count,1
      assert_equal text_hash_array[2],text_hash_1
    end
  end

  def repo_test
    lifei = users(:repo_lifei)
    clear_user_repositories(lifei)
    yield lifei
#    clear_user_repositories(lifei)
  end

  def clear_user_repositories(user)
    FileUtils.rm_rf(NoteRepository.user_repository_path(user.id))
    FileUtils.rm_rf(NoteRepository.user_recycle_path(user.id))
  end
  
end
