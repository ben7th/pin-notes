class NoteRepository
  if RAILS_ENV != "test"
    REPO_BASE_PATH = YAML.load(CoreService.project("pin-notes").settings)[:note_repo_path]
  else
    REPO_BASE_PATH = "/root/mindpin_base/note_repo_test"
  end

  NOTE_FILE_PREFIX = "notefile_"
  
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

  # 设置提交者为版本库的创建者
  def set_creator_as_commiter
    user = User.find(@user_id)
    @repo.config['user.name'] = user.name
    @repo.config['user.email'] = user.email
  end

  # 编辑文本片段
  # _text_hash 格式
  # {"notefile_1"=>"xx","notefile_2"=>"yy"...}
  def replace_notefiles(_text_hash)
    # 设置提交者
    set_creator_as_commiter
    # 对比 self.text_hash 和 _text_hash 找到需要写入的 文本片段
    write_hash = find_text_hash_of_need_to_write(_text_hash)
    # 把 文本片段 写入文件
    create_or_edit_notefiles(write_hash)
    # 对比 self.text_hash 和 _text_hash 找到要删除的文件
    delete_names = self.text_hash.keys - _text_hash.keys
    # 删除 文本片段
    delete_notefiles(delete_names)
    # 提交到版本库
    @repo.commit_index("##")
  end

  # 对比 self.text_hash 和 new_hash 找到需要写入的 文本片段
  def find_text_hash_of_need_to_write(new_hash)
    old_hash = self.text_hash
    need_write_hash = {}
    # 对比 self.text_hash 和 _text_hash 找到要编辑的文本 和 新增的文本
    new_hash.each do |name,text|
      is_new = old_hash[name].blank?
      is_edit = (old_hash[name] != text)
      need_write_hash[name] = text if is_new || is_edit
    end
    need_write_hash
  end

  # 把 文本片段 写入文件
  def create_or_edit_notefiles(_text_hash)
    _text_hash.each do |name,text|
      # 根据 text 生成文件
      absolute_file_path = File.join(path,name)
      File.open(absolute_file_path,"w") do |f|
        f << text
      end
    end
    @repo.add(_text_hash.keys)
  end

  # 删除文件
  def delete_notefiles(delete_names)
    delete_names.each do |notefile_name|
      absolute_file_path = File.join(path,notefile_name)
      raise "要删除的文件不存在" if !File.exist?(absolute_file_path)
      @repo.remove(notefile_name)
    end
  end

  # 找到当前最大的编号
  def current_max_id
    ids = _notefile_blob("master").map do |blob|
      blob.name.sub(NOTE_FILE_PREFIX,"").to_i
    end
    ids << 0
    ids.max
  end

  # 得到所有的版本号,新版本号在数组的前面
  def commit_ids
    @repo.commits.map{|commit|commit.id}
  end

  # 得到某一个版本下的 所有 文本片段
  def text_hash(commit_id = "master")
    hash = {}
    _notefile_blob(commit_id).map do |blob|
      hash[blob.name] = blob.data
    end
    hash
  end

  # 获取文件片段的个数
  def notefile_count(commit_id = "master")
    _notefile_blob(commit_id).count
  end

  # 代表 文件片段的 blob 对象数组
  def _notefile_blob(commit_id)
    contents = @repo.commit(commit_id) ? @repo.commit(commit_id).tree.contents : []
    contents.select do |item|
      item.instance_of?(Grit::Blob) && !!item.name.match(NOTE_FILE_PREFIX)
    end
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