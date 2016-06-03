json.array!(@users) do |user|
  json.extract! user, :id, :email, :nickname, :hashed_password, :salt, :access_level
  json.url user_url(user, format: :json)
end
