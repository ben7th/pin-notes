class NoteRepository
  REPO_BASE_PATH = YAML.load(CoreService.project("pin-notes").settings)[:note_repo_path]

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

  # 为新的文本片段指定编号，并转换成 HASH的形式
  def convert_new_texts_to_hash(texts)
    count = notefile_count
    text_hashs = []
    texts.each_with_index do |text,index|
      text_hashs << {:name=>"#{NOTE_FILE_PREFIX}#{count + index + 1}",:text=>text}
    end
    text_hashs
  end

  # 把 文本片段 写入文件
  def create_or_edit_notefiles(text_hashs)
    text_hashs.each do |text_hash|
      # 根据 text 生成文件
      absolute_file_path = File.join(path,text_hash[:name])
      File.open(absolute_file_path,"w") do |f|
        f << text_hash[:text]
      end
    end
  end

  # 增加文本片段
  # text_or_text_array 可以是 字符串，或者字符串数组
  def add_notefiles(text_or_text_array)
    # 把 text_or_text_array 转换成数组
    texts = text_or_text_array.instance_of?(Array) ? text_or_text_array : [text_or_text_array]
    # 为新的文本片段指定编号，并转换成 HASH的形式
    _text_hashs = convert_new_texts_to_hash(texts)
    edit_notefiles(_text_hashs)
  end

  # 编辑文本片段
  # text_hashs 格式
  # [{:name=>"notefile_1",:text=>"xx"},{:name=>"notefile_2",:text=>"yy"}..]
  def edit_notefiles(_text_hashs)
    # 设置提交者
    set_creator_as_commiter
    # 把 文本片段 写入文件
    create_or_edit_notefiles(_text_hashs)
    # 提交到版本库
    notefile_names = _text_hashs.map{|text_hash|text_hash[:name]}
    @repo.add(notefile_names)
    @repo.commit_index("##")
  end

  # 删除文本片段
  def delete_notefile(notefile_name)
    # 设置提交者
    set_creator_as_commiter
    absolute_file_path = File.join(path,notefile_name)
    raise "要删除的文件不存在" if !File.exist?(absolute_file_path)
    @repo.remove(notefile_name)
    @repo.commit_index("##")
  end

  # 得到所有的版本号,新版本号在数组的前面
  def commit_ids
    @repo.commits.map{|commit|commit.id}.reverse
  end

  # 得到某一个版本下的 所有 文本片段
  def text_hashs(commit_id = "master")
    _notefile_blob(commit_id).map do |blob|
      {:name=>blob.name,:text=>blob.data}
    end
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