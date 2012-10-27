module Griddler::EmailFormat
  LocalPartSpecialChars = Regexp.escape('!#$%&\'*-/=?+-^_`{|}~')
  LocalPartUnquoted = '(([[:alnum:]' + LocalPartSpecialChars + ']+[\.\+]+))*[[:alnum:]' + LocalPartSpecialChars + '+]+'
  LocalPartQuoted = '\"(([[:alnum:]' + LocalPartSpecialChars + '\.\+]*|(\\\\[\u0001-\uFFFF]))*)\"'
  Regex = Regexp.new('((' + LocalPartUnquoted + ')|(' + LocalPartQuoted + ')+)@(((\w+\-+)|(\w+\.))*\w{1,63}\.[a-z]{2,6})', Regexp::EXTENDED | Regexp::IGNORECASE)
end
