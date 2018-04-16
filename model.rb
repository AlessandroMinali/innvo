# frozen_string_literal: true

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://poll.db')

unless DB.tables.include? :ideas
  DB.create_table :ideas do
    primary_key :id
    Integer :user_id
    String :title, unique: true
    String :desc
  end
end

unless DB.tables.include? :users
  DB.create_table :users do
    primary_key :id
    String :email, unique: true
    String :token, unique: true
    String :uuid, unique: true
  end
end

unless DB.tables.include? :votes
  DB.create_table :votes do
    primary_key :id
    Integer :user_id
    Integer :idea_id
    String :vote
  end
end

class Idea < Sequel::Model
  many_to_one :user
  one_to_many :votes

  def likes
    votes_dataset.where(vote: 'up').count
  end

  def super_likes
    votes_dataset.where(vote: 'heart').count
  end

  def dislikes
    votes_dataset.where(vote: 'down').count
  end
end

class User < Sequel::Model
  one_to_many :ideas
  one_to_many :votes
end

class Vote < Sequel::Model
  many_to_one :ideas
  many_to_one :user
end

def fake_string(length)
  string = ''
  string << ('a'..'z').to_a.shuffle.join while string.length < length
  string[0..length]
end

# 3.times do
#   Idea.create(user_id: rand(10),
#               title: fake_string(12),
#               desc: fake_string(140),
#               likes: rand(20),
#               super_likes: rand(3),
#               dislikes: rand(10))
# end if Idea.count.zero? and settings.development?
