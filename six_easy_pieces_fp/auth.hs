import System.Environment (getArgs)

data Login = User String | Login String String | Token String
             deriving (Show)

login :: Login -> Bool
login (User s) = True
    where validLogins = ["bishop", "whistler", "mother", "carl"]
login (Login username password) = (username, password) `elem` validLogins
    where validLogins = [("adam", "letmein"), ("alice", "sekrit"), ("bob", "foo")]
login (Token t) = t `elem` validTokens
    where validTokens = ["0xdeadbeef", "myvoiceismypasswordverifyme"]

main = do
  args <- getArgs
  let method = case head args of
                 "user" -> User (args !! 1)
                 "login" -> Login (args !! 1) (args !! 2)
                 "token" -> Token (args !! 1)
  case login method of
    True -> putStrLn "You are authorized"
    False -> putStrLn "Access denied!"



