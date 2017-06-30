window.string_to_float = (string) ->
  # Replace all Currency Symbols, Letters and -- from the string
  string = string.replace(/[^0-9\.,]+/g, '')
  # If string ends in a single digit (e.g. ,2) make it ,20 in order for the result to be in "cents"
  if string.match(/[\.,]\d$/)
    string = string + '0'
  # If does not end in ,00 / .00 then
  # add trailing 00 to turn it into cents
  if !string.match(/[\.,]\d\d$/)
    string = string + '00'
  # Replace all Currency Symbols, Letters and -- from the string
  string = string.replace(/[\.,]/g, '')
  string / 100
