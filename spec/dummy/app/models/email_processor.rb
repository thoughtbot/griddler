class EmailProcessor
  cattr_accessor :email
  def self.process(email)
    @@email = email
  end
end
