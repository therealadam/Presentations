import Data.List (intercalate)

class Addressable a where
    address :: a -> String

data Residence = Residence String String String String
                 deriving (Show, Read, Eq)

instance Addressable Residence where
    address (Residence street city state zip) = join parts
        where parts = ["(Residence)", street, city, state, zip]

data Business = Business {
      attention :: String,
      street :: String,
      city :: String,
      state :: String,
      -- So as not to conflict with Prelude.zip
      bZip :: String
    }
                deriving (Show, Read, Eq)

instance Addressable Business where
    address b = join parts
      where parts = ["(Business)", attention b, street b, city b, state b, bZip b]

mail :: Addressable a => String -> a -> IO ()
mail msg addr = putStrLn message
    where message = join parts
          parts = ["Mailing message: ", msg, "to: ", address addr]

-- A more-familiar looking helper
join :: [String] -> String
join = intercalate "\n" -- NB: In Haskell, we can "curry" and omit the last parameter

main = do
  mail msg r
  where r = Residence "123 Main" "Dallas" "Texas" "75201"
        msg = "Hello, from Developer Day Austin!"

-- *Main> :load "addresses.hs"
-- [1 of 1] Compiling Main             ( ../Desktop/In/six_easy_pieces_fp/addresses.hs, interpreted )
-- Ok, modules loaded: Main.
-- *Main> :main
-- Mailing message: 
-- Hello, from Developer Day Austin!
-- to: 
-- (Residence)
-- 123 Main
-- Dallas
-- Texas
-- 75201
