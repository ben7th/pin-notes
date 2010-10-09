ActionController::Routing::Routes.draw do |map|
  map.root :controller => "notes",:action=>"new"
  map.mine_notes "/mine",:controller=>"notes",:action=>"index",:conditions => { :method => :get }
  map.show_note "/:note_id/:commit_id",
    :controller=>"notes",:action=>"show",:commit_id=>"master",
    :requirements => { :note_id => /[0-9]+/,:commit_id=>/master|\w{40}+/ },:conditions => { :method => :get }
  map.create_note "notes",:controller=>"notes",:action=>"create",:conditions => { :method => :post }
  map.edit_note "/:note_id/edit",:controller=>"notes",:action=>"edit",:conditions => { :method => :get }
  map.update_note "/:note_id",:controller=>"notes",:action=>"update",:conditions => { :method => :put }
  map.destroy_note "/:note_id",:controller=>"notes",:action=>"destroy",:conditions => { :method => :delete }
  map.new_file "notes/new_file",:controller=>"notes",:action=>"new_file",:conditions => { :method => :post }
end
