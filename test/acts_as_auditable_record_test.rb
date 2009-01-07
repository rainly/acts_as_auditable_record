#Testing this plugin requires a database be created.  Use the database.yml in this directory.
#Once it's created comment the line that creates the tables in the test_helper.rb.
require File.dirname(__FILE__) + '/test_helper'

#author tests the message_proc format and basic formatting and :only indicator.
class Author < ActiveRecord::Base  
  msg_proc = Proc.new {|a, b| "Last Name changed to #{b}"}
  acts_as_auditable_record :only=>[:last_name => {:message_proc=>msg_proc}]
  has_many :articles  
end

#article tests compare_proc and format_proc and the :all indicator
class Article < ActiveRecord::Base
  format_proc = Proc.new{|d| d.strftime('%m/%d/%y')}
  compare_proc = Proc.new{|a,b| a.strftime('%m/%d/%y') != b.strftime('%m/%d/%y')}
  author_format_proc = Proc.new{|a| Author.find(a).name}
  acts_as_auditable_record :all => [:deactivated_at=>{:format_proc=>format_proc, :compare_proc=>compare_proc},
                                    :author_id=>{:format_proc=>author_format_proc},
                                    :note=>{}]
  belongs_to :author
  has_many   :comments
  attr_accessor :note  
end

#comment tests :all with :except
class Comment < ActiveRecord::Base  
  acts_as_auditable_record :all=>[:body=>{:descriptor=>'Comment'}],
                           :except=>[:user_id] 
  belongs_to :article
  belongs_to :user  
end

#User tests the default of :all
class User < ActiveRecord::Base
  acts_as_auditable_record
  has_many :comments  
end 

class ActsAsAuditableRecordTest < Test::Unit::TestCase
  fixtures :authors, :articles, :comments, :users 
  
  def test_fixture_loads    
    assert Author.find(:all).size > 0
    assert Article.find(:all).size > 0
    assert Comment.find(:all).size > 0
    assert User.find(:all).size > 0
  end
  
  def test_message_proc
    author = Author.find(1)
    last_name = 'Newlastname'
    author.last_name = last_name
    author.save
    assert_equal "Last Name changed to #{last_name}.", author.audit_report[0] 
  end
  
  def test_descriptor
    comment = Comment.find(1)
    old_body = comment.body    
    new_body = 'Hello there'
    old_article_id = comment.article_id
    new_article_id = 2
    comment.body = new_body
    comment.article_id = new_article_id
    comment.save
    assert_equal "Comment changed from: #{old_body} to: #{new_body}.", comment.audit_report[0]
    assert_equal "Article changed from: #{old_article_id} to: #{new_article_id}.", comment.audit_report[1]
  end
  
  def test_all_with_except
    comment = Comment.find 1
    comment.article_id = 99
    comment.user_id = 99
    comment.body = "New body"
    comment.save
    assert_equal 2, comment.audit_report.size
  end
  
  def test_when_no_change
    author = Author.find(1)        
    author.save
    assert author.audit_report.empty?
  end
  
  def test_default_to_all
    user = User.find 1
    user.first_name = "Eye"
    user.last_name = "Changed"
    user.username = "myusername"
    user.save
    assert_equal 3, user.audit_report.size
  end
  
  def test_with_only
    author = Author.find 2
    author.last_name = "Newlastname"
    author.first_name = "Newfirstname"
    author.save
    assert_equal 1, author.audit_report.size    
  end
  
  def test_change_string
    article = Article.find(1)
    old_title = article.title
    new_title = 'my new title'
    article.title = new_title
    article.save
    assert_equal "Title changed from: #{old_title} to: #{new_title}.", article.audit_report[0]
  end
  
  def test_non_persisted_attribute
    article = Article.find(1)
    article.note = 'Brand new note'
    article.save
    assert_equal "Note changed to: Brand new note.", article.audit_report[0]
  end
  
  def test_change_date
    article = Article.find(1)
    time = Time.now
    time_str = time.strftime('%m/%d/%Y')
    article.deactivated_at = time
    article.save
    assert_equal "Deactivated at changed to: #{time.strftime('%m/%d/%y')}.", article.audit_report[0]
    
    article.deactivated_at = time.strftime('%m/%d/%y')
    article.save
    assert article.audit_report.blank?
    
    #ensure the existing record is not a utc time.
    assert !article.deactivated_at.utc?
    #make deactivated_at a utc time    
    article.deactivated_at = Time.mktime(time.year, time.month, time.day).utc
    assert article.deactivated_at.utc?
    article.save
    assert article.audit_report.blank?
    
    article.deactivated_at = Time.parse(time_str)
    article.save
    assert article.audit_report.blank?
    
    tomorrow = time + 1.day
    article.deactivated_at = tomorrow
    article.save
    assert_equal "Deactivated at changed from: #{time.strftime('%m/%d/%y')} to: #{tomorrow.strftime('%m/%d/%y')}.", article.audit_report[0]
  end
  
end
