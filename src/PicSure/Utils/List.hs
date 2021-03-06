module PicSure.Utils.List where

import Data.List
import PicSure.Utils.Misc

---------------------------------------------------
{- SAFE -}

safe_part f l = if isEmpty l then Nothing else Just $ f l
safe_head = safe_part head
safe_tail = safe_part tail
safe_last = safe_part last

-- isEmpty :: (Foldable t, Functor t) => t a -> Bool
-- isEmpty = (==0) . count
isEmpty :: [α] -> Bool
isEmpty [] = True
isEmpty _  = False

groupBy :: (Eq a,Ord a) => (a -> a -> Ordering) -> [a] -> [[a]]
groupBy f = foldl' insert []
  where insert acc e = walk acc
          where walk [] = [[e]]
                walk (l@(x:_):ls) | f x e == EQ = append e l : ls
                                   | otherwise = l : walk ls

groupBy' :: (Eq b,Ord b) => (a -> b) -> [a] -> [[a]]
groupBy' f = foldl' insert []
  where insert acc e = walk acc
          where walk [] = [[e]]
                walk (l@(x:xs):ls) | compare (f x) (f e) == EQ = append e l : ls
                                   | otherwise = l : walk ls

-- slice '/' "45/3"
-- -> ("45","3") 
slice :: (Eq α) => α -> [α] -> ([α],[α])
slice e = (\ (a,b) -> (a,
                       if length b > 1
                       then tail b
                       else []))
          . break (==e)


split :: (Eq α) => α -> [α] -> [[α]]
split _ [] = []
split sep l =
  let (a,b) = break (==sep) l in
  case b of
    [] -> [a]
    _ -> a : (split sep $ tail b)

-- reduce :: (t -> t -> t) -> [t] -> t
reduce _ [] = error "reduce empty list"
reduce _ [x] = error $ "reduce single element"
reduce f l = foldl' f (head l) (tail l)

maxSize :: [[α]] -> Int
maxSize = reduce max . map length

sliceN :: Int -> [α] -> ([α],[α])
sliceN = (`sliceN'`[])
  where sliceN' 0 a b = (reverse a,b)
        sliceN' _ a [] = sliceN' 0 a []
        sliceN' k a (x:xs) =
          sliceN' (k-1) (x:a) xs

sliceOn :: Eq α => α -> [α] -> ([α],[α])
sliceOn c l = (a,b')
  where (a,b) = span (/=c) l
        b' = if isEmpty b then b else tail b


--append x l = foldr (:) [x] l

splitEach :: Int -> [α] -> [[α]]
splitEach _ [] = []
splitEach k l = (take k l) : (splitEach k . drop k $ l)


uniq l = uniq' l []
  where uniq' [] _ = []
        uniq' (x:xs) l
          | x `elem` l = uniq' xs l
          | otherwise  = x : uniq' xs (x:l)

splitOn :: (α -> Bool) -> [α] -> [[α]]
splitOn _ [] = []
splitOn f l@(x:xs)
  | f x  = splitOn f xs
  | otherwise = foldr f' [[]] l
  where f' e acc@(a:as)
          | f e = ([]:acc)
          | otherwise = ((e:a) : as)


-- lines generalized
-- first arg is the list delimiter
splitWhen :: (Eq a) => [a] -> [a] -> [[a]]
splitWhen sep l = sp l [] []
  where sp [] acc s = acc++[s]
        sp l@(x:xs) acc s
          | isPrefixOf sep l = sp (dropk l) (acc++[s]) []
          | otherwise       = sp xs        acc        (s++[x])
        dropk = drop (length sep)

contains :: Eq α => [α] -> [α] -> Bool
contains [] _ = True
contains _ [] = False
contains la@(a:as) lb@(b:bs)
  | a == b = check la lb || contains la bs
  | otherwise = contains la bs
  where check [] _ = True
        check _ [] = False
        check (a:as) (b:bs) = a == b && check as bs

append = (flip (++)) . (:[])

quickSortBy :: Ord β => (α -> β) -> [α] -> [α]
quickSortBy _ [] = []
quickSortBy f (pivot:xs) = (qs α) ++ ( pivot : (qs β))
  where qs = quickSortBy f
        sort p [] τ π = (τ,π)
        sort p (x:xs) τ π
          | (f x) `compare` (f p) == LT    = sort p xs (x:τ) π
          | otherwise                      = sort p xs τ (x:π)
        (α,β) = sort pivot xs [] []


quickSort :: Ord α => [α] -> [α]
quickSort = quickSortBy id

-- letter
replace a b = fmap (\ e -> if e == a then b else e)

-- any
-- todo fold, tail recursion
replaceStr a b [] = []
replaceStr a b str | isPrefixOf a str = b ++ replaceStr a b (drop k str)
                   | otherwise = head str : (replaceStr a b $ tail str)
  where k = length a

trimWith :: (α -> Bool) -> [α] -> [α]
trimWith f = applyN 2 (dropWhile f . reverse)

-- trimsp = dropWhile (==' ') . reverse . dropWhile (==' ') . reverse
trimsp = trimWith (==' ')
trim = trimWith (`elem` " \t\n\r")

surround2 a b = (a++) . (++b)
surround a = surround2 a a

surroundWith s = (s++) . (++s)

-- basename = last . filter (not . isEmpty) . splitOn (=='/')

fix'size'side side k e s = f . take k $ s
  where f = if side==1 then (mappend strfill) else (`mappend` strfill)
          where strfill = take (max 0 (k-length s)) (repeat e) 

fix'size = fix'size'side 0

allToMaxSize e l = if length l <= 1 then l else map (fix'size k e) l
  where k = maxSize l

nice'title s = unlines
  . surround2 [horiz "┌" "┐"] [horiz "└" "┘"] $ ls'
  where horiz a b = surround2 a b $ take n $ repeat '─'
          where n = length (head ls') - 2
        f = surround2 "│ " " │"
        ls' = map f . allToMaxSize ' ' . concatMap (splitEach 150) . lines $ s

intercal :: α -> [α] -> [α]
intercal _ [] = []
intercal _ [x] = [x]
intercal e (x:xs) = x : e : intercal e xs

afterEach :: α -> [α] -> [α]
afterEach e = (++[e]) . intercal e
