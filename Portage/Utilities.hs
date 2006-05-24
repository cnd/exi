{-|
    Maintainer  :  Andres Loeh <kosmikus@gentoo.org>
    Stability   :  provisional
    Portability :  haskell98

    Common utilities module.
-}

module Portage.Utilities
  where

import Prelude hiding (catch)
import Control.Exception
import System.Directory
import System.IO
import Data.List
import Data.Maybe (fromJust)
import Data.Map (Map)
import qualified Data.Map as Map

-- | Implements a "spinner".
spin :: Int -> String -> String
spin w = spin' w
  where spin' _ []           =  []
        spin' 0 xs           =  replicate w '\b' ++ spin' w xs
        spin' c xs@('\n':_)  =  xs
        spin' c (x:xs)       =  x : ' ' : '\b' : spin' (c-1) xs

-- | Aligns a table of strings.
align :: [[String]] -> String
align ts =  let  maxlengths = map (maximum . map length) (transpose ts)
            in   unlines . map (concat . zipWith formatIn maxlengths) $ ts
  where  formatIn :: Int -> String -> String
         formatIn n s = s ++ replicate (n - length s) ' '

-- | Variant of |words| that accepts a custom separator.
split :: Char -> String -> [String]
split c s = case dropWhile (==c) s of
              ""  ->  []
              s'  ->  w : split c s''
                        where (w, s'') = break (==c) s'

-- | Group a number of elements.
groupnr :: Int -> [a] -> [[a]]
groupnr n = map (take n) . takeWhile (not . null) . iterate (drop n)

-- | Split a list at the last occurrence of an element.
splitAtLast :: (Eq a) => a -> [a] -> ([a],[a])
splitAtLast s xs  =   splitAt (maximum (elemIndices s xs)) xs

-- | Sort a list according to another list.
sortByList :: Ord b => [a] -> (a -> b) -> [b] -> [a]
sortByList xs p rs =  let  m = Map.fromList (zip rs [1..])
                      in   sortBy (\x y -> compare (m Map.! p x) (m Map.! p y)) xs

-- | Group by first element.
groupByFst :: Ord a => [(a,b)] -> [(a,[b])]
groupByFst  =  Map.toList . Map.fromListWith (++) . reverse . map (\ (x,y) -> (x,[y]))

-- | Reads a file completely into memory.
strictReadFile :: FilePath -> IO String
strictReadFile f  =   do  f <- readFile f
                          f `stringSeq` return f

-- | Reads a file completely into memory. Returns the
--   empty string if the file does not exist.
strictReadFileIfExists :: FilePath -> IO String
strictReadFileIfExists f  =   do  x <- doesFileExist f
                                  if x then strictReadFile f else return []

-- | Normalize the end of a file to a newline character.
normalizeEOF :: FilePath -> IO ()
normalizeEOF f  =  do  h  <-  openFile f ReadWriteMode
                       c  <-  catch  (do  hSeek h SeekFromEnd (-1)
                                          hGetChar h)
                                     (const $ return '\n')
                       case c of
                         '\n'  ->  return ()
                         _     ->  hPutChar h '\n'
                       hClose h

-- | Completely evaluates a string.
stringSeq :: String -> b -> b
stringSeq []      c  =  c
stringSeq (x:xs)  c  =  stringSeq xs c

-- | Concatenate two paths.
(./.) :: FilePath -> FilePath -> FilePath
path ./. file  =  path ++ "/" ++ file

-- | Checks if one list is contained in another.
contains :: Eq a => [a] -> [a] -> Bool
contains x y = any (x `isPrefixOf`) (tails y)

-- | Strip empty lines and comments from a string.
stripComments :: String -> String
stripComments = unlines . filter (not . null) . map (fst . break (=='#')) . lines

-- | Strip newline characters.
stripNewlines :: String -> String
stripNewlines = filter (/='\n')

-- | Reads a string into a map from strings to strings.
readStringMap :: [String] -> Map String String
readStringMap = Map.fromList . map ((\ (x,y) -> (x,tail y)) . break (=='='))

-- | Writes a map from strings to strings into a collapsed string.
writeStringMap :: Map String String -> [String]
writeStringMap = sortBy underscoreFirst . map (\ (x,y) -> x ++ "=" ++ y) . Map.toList
  where  underscoreFirst ('_':_)  ('_':_)  =  EQ
         underscoreFirst ('_':_)  _        =  LT
         underscoreFirst _        ('_':_)  =  GT
         underscoreFirst _        _        =  EQ

-- | The function 'splitPath' is a reimplementation of the Python
--   function @os.path.split@.
splitPath :: FilePath 
          -> (FilePath,  -- the part before the final slash; may be empty
              FilePath)  -- the part after the final slash; may be empty
splitPath p
    = let
          slashes = elemIndices '/' p 
          index   = if null slashes then 0 else last slashes + 1
          (hd,tl) = splitAt index p
          fhd | null hd || hd `isPrefixOf` repeat '/'
                  = hd
              | otherwise
                  = reverse . dropWhile (=='/') . reverse $ hd
      in
          (fhd,tl)

-- | The function 'dirname' is a reimplementation of the Python function
--   @os.path.dirname and@ returns the directory component of a pathname.
dirname :: FilePath -> FilePath
dirname = fst . splitPath

-- | The function 'basename' is a reimplementation of the Python function
--   @os.path.basename@ and returns the non-directory component of a pathname.
basename :: FilePath -> FilePath
basename = snd . splitPath

-- | Variant of 'head' that takes a location.
head' :: String -> [a] -> a
head' err []     =  error ("(" ++ err ++ ") empty list")
head' err (x:_)  =  x

-- | Variant of 'fromJust' that takes a location.
fromJust' :: String -> Maybe a -> a
fromJust' err Nothing   =  error ("(" ++ err ++ ") fromJust applied to Nothing")
fromJust' err (Just x)  =  x
