# class Tst

#   def write
#     self.session_lang = 'ru'
#   end

#   def read
#     self.session_lang
#   end

#   private

#   def session_lang
#     p 'read'
#   end

#   def session_lang= (value)
#     p 'write'
#   end
# end

# tst = Tst.new
# tst.write
# tst.read




def session_key
  # from = { 'id' => 55 }
  if (subject = from || chat) then "#{subject['id']}" end
end

p session_key
