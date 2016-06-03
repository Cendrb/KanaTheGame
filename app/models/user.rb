class User < ApplicationRecord
  validates_presence_of :access_level, :email, :nickname
  validates_uniqueness_of :email, :nickname
end
