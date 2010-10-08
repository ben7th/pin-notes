class NoteRepository
  REPO_BASE_PATH = YAML.load(CoreService.project("pin-notes").settings)[:note_repo_path]

  attr_reader :repo,:user_id,:note_id

  def initialize(hash)
    @user_id = hash[:user_id]
    @note_id = hash[:note_id]

    NoteRepository.init_user_path(@user_id)

    @repo = Grit::Repo.new(self.path) if File.exist?(self.path)
  end

  # 该 git 版本库 的路径
  def path
    NoteRepository.repository_path(@user_id,@note_id)
  end

  # 删除一个版本库
  # 其实是把该版本库 放入 回收站 目录
  def destroy
    return false if !File.exist?(path)
    recycle_path = NoteRepository.user_recycle_path(@user_id)
    `mv #{path} #{recycle_path}/#{@note_id}_#{randstr}`
    return true
  end

  class << self
    # 初始化 用户用到的 所有地址
    def init_user_path(user_id)
      self.init_user_repository_path(user_id)
      self.init_user_recycle_path(user_id)
    end

    # 初始化 用户的 版本库 根地址
    def init_user_repository_path(user_id)
      path = self.user_repository_path(user_id)
      FileUtils.mkdir_p(path) if !File.exist?(path)
    end

    # 初始化 用户的 回收站 地址
    def init_user_recycle_path(user_id)
      path = self.user_recycle_path(user_id)
      FileUtils.mkdir_p(path) if !File.exist?(path)
    end

    # 用户的 版本库 根地址
    def user_repository_path(user_id)
      "#{REPO_BASE_PATH}/users/#{user_id}"
    end

    # 用户的 回收站 地址
    def user_recycle_path(user_id)
      "#{REPO_BASE_PATH}/deleted/users/#{user_id}"
    end

    # 用户 的 某个版本库 地址
    def repository_path(user_id,note_id)
      "#{self.user_repository_path(user_id)}/#{note_id}"
    end

    # 创建一个 git 版本库
    # nrepo = NoteRepository.create(:user_id=>user_id,:note_id=>note_id)
    def create(hash)
      raise "user_id 不能为空" if hash[:user_id].blank?
      raise "note_id 不能为空" if hash[:note_id].blank?

      _path = self.repository_path(hash[:user_id],hash[:note_id])
      g = Grit::Repo.init(_path)
      # git config core.quotepath false
      # core.quotepath设为false的话，就不会对0x80以上的字符进行quote。中文显示正常
      g.config["core.quotepath"] = "false"
    end

    # 找到某个版本库
    def find(hash)
      raise "user_id 不能为空" if hash[:user_id].blank?
      raise "note_id 不能为空" if hash[:note_id].blank?

      path = self.repository_path(hash[:user_id],hash[:note_id])
      return nil if !File.exist?(path)
      NoteRepository.new(hash)
    end
  end
end