Telegram::Bot::Types::Base.class_eval do
  def to_hash(*)
    super.reject { |_k, v| v.nil? }
  end
end
