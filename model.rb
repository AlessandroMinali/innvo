# frozen_string_literal: true

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://poll.db')

unless DB.tables.include? :ideas
  DB.create_table :ideas do
    primary_key :id
    String :uuid, unique: true, null: false
    Integer :user_id, null: false
    String :title, unique: true, null: false
    String :desc, null: false
  end
end

unless DB.tables.include? :users
  DB.create_table :users do
    primary_key :id
    String :email, unique: true, null: false
    String :token, unique: true
    String :uuid, unique: true, null: false
    Integer :role
  end
end

unless DB.tables.include? :votes
  DB.create_table :votes do
    primary_key :id
    Integer :user_id, null: false
    Integer :idea_id, null: false
    String :vote, null: false
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
  string += ('a'..'z').to_a.shuffle.join while string.length < length
  string[0..length]
end

if settings.development?
  if Idea.count.zero?
    3.times do
      Idea.create(user_id: rand(10),
                  uuid: SecureRandom.uuid,
                  title: fake_string(12),
                  desc: fake_string(140))
    end
  end
  User.create(email: 'example@test.com', uuid: SecureRandom.uuid, role: 1) if User.count.zero?
end
