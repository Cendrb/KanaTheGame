class User < ApplicationRecord
  validates_presence_of :access_level, :email, :nickname
  validates_uniqueness_of :email, :nickname
  validate :password_must_be_present

  has_many :match_signups

  attr_accessor :password_confirmation
  attr_reader :password

  def current_match
    return Match.joins(:match_signups).where('started = true AND match_signups.user_id = ?', self.id).first
  end

  def password=(password)
    @password = password

    if password.present?
      generate_salt
      self.hashed_password = self.class.encrypt_password(password, salt)
    end
  end

  private
  def password_must_be_present
    errors.add(:password, "chybí") unless hashed_password.present?
  end

  private
  def generate_salt
    self.salt = self.object_id.to_s + rand.to_s
  end

  # Static
  def User.encrypt_password(password, salt)
    Digest::SHA2.hexdigest(password + "kanakanakanakanakana" + salt)
  end

  def User.authenticate(email, password)
    if user = find_by_email(email)
      if user.hashed_password == encrypt_password(password, user.salt)
        user
      end
    end
  end

  # Constants
  def User.al_admin
    return 9
  end

  def User.al_superuser
    return 10
  end

  def User.al_registered
    return 5
  end

  def User.access_levels
    return %w(superuser administrátor registrovaný)
  end

  def User.get_access_level_string(number)
    case number
      when User.al_registered
        return "registrovaný"
      when User.al_superuser
        return "superuser"
      when User.al_admin
        return "administrátor"
    end
  end

  def User.parse_access_level(string)
    case string
      when "registrovaný"
        return User.al_registered
      when "superuser"
        return User.al_superuser
      when "administrátor"
        return User.al_admin
    end
  end
end
