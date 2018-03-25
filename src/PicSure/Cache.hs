{-# LANGUAGE DuplicateRecordFields #-}
module PicSure.Cache where

import PicSure.Utils.Trees
import PicSure.Utils.Paths
import PicSure.Utils.Misc
import PicSure.Types

import System.IO.Strict

import Data.Monoid
import Control.Monad
import Control.Monad.Trans.State
import Control.Monad.IO.Class (liftIO)

addToCache :: PicState -> [Char] -> PicState
addToCache (PicState {config=c, cache=cache}) path = PicState{
  config=c,
  cache=cache <> fromList (tail $ splitPath path)
  }

persistCache :: StateT PicState IO ()
persistCache = do
  s@PicState{config=Config{cacheFile=path}, cache=cache} <- get
  -- liftIO $ print ("cache", addToCache s )
  when (path/=Nothing) $ liftIO . writeFile (fromJust path) . show $ cache

invalidateCache :: StateT PicState IO ()
invalidateCache = do
  config <- gets config
  put PicState{config=config, cache=cacheRoot}
  -- persistCache
