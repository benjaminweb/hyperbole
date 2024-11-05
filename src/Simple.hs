{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-missing-signatures #-}

module Simple where

import Data.Text (pack)
import Effectful
import Web.Hyperbole


main = do
  run 3000 $ do
    liveApp (basicDocument "Example") (page simplePage)


simplePage :: (Hyperbole :> es, IOE :> es) => Page es '[MainView, Status]
simplePage = do
  load $ do
    liftIO $ putStrLn "MAIN LOAD"
    pure $ col (pad 20) $ do
      el bold "My Page"
      hyper MainView $ do
        row (gap 10) $ do
          button GoBegin (border 1) "Start"


simplePage1 :: (Hyperbole :> es, IOE :> es) => Page es '[Floop]
simplePage1 = do
  load $ do
    liftIO $ putStrLn "MAIN LOAD"
    pure $ col (pad 20) $ do
      el bold "My Page"
      hyper Floop $ do
        row (gap 10) $ do
          button FloopA (border 1) "Start"


simplePage0 :: (Hyperbole :> es, IOE :> es) => Page es '[]
simplePage0 = do
  load $ do
    liftIO $ putStrLn "MAIN LOAD"
    pure $ col (pad 20) $ do
      el bold "My Page"


data Floop = Floop
  deriving (Show, Read, ViewId)


data FloopA = FloopA
  deriving (Show, Read, ViewAction)


instance HyperView Floop where
  type Action Floop = FloopA
instance Handle Floop es where
  handle _ _ = pure none


-- MAIN ----------------------------------------

data MainView = MainView
  deriving (Show, Read, ViewId)


data MainAction
  = GoBegin
  | GoMid
  | GoEnd
  deriving (Show, Read, ViewAction)


instance HyperView MainView where
  type Action MainView = MainAction
  type Require MainView = '[Status]
instance Handle MainView es where
  handle _ = \case
    GoBegin -> pure beginStep
    GoMid -> pure middleStep
    GoEnd -> pure endStep


beginStep :: View MainView ()
beginStep = do
  el_ "BEGIN"
  button GoMid (border 1) " Mid"


middleStep :: View MainView ()
middleStep = do
  el_ "MIDDLE: running"
  button GoBegin (border 1) "Back"
  hyper Status $ statusView 0


endStep :: View MainView ()
endStep = do
  el_ "END"
  button GoMid (border 1) "Back"


-- Status ---------------------------------------

data Status = Status
  deriving (Show, Read, ViewId)


data CheckStatus
  = CheckStatus Int
  deriving (Show, Read, ViewAction)


instance HyperView Status where
  type Action Status = CheckStatus
instance Handle Status es where
  handle _ = \case
    CheckStatus n ->
      if n >= 5
        then pure lazyEnd
        else pure $ statusView (n + 1)


statusView :: Int -> View Status ()
statusView n = do
  onLoad (CheckStatus n) 1000 $ do
    el_ $ text $ "Checking Status" <> pack (show n)


lazyEnd :: View Status ()
lazyEnd = do
  el_ "Lazy End"
  target MainView $ do
    button GoEnd (border 1) "Go End"

-- {-# LANGUAGE DeriveAnyClass #-}
-- {-# LANGUAGE LambdaCase #-}
-- {-# LANGUAGE OverloadedStrings #-}
-- {-# LANGUAGE TypeFamilies #-}
-- {-# LANGUAGE UndecidableInstances #-}
-- {-# OPTIONS_GHC -Wno-missing-signatures #-}
--
-- module Simple where
--
-- import Data.Text (Text, pack)
-- import Effectful
-- import Effectful.Concurrent.STM
-- import Effectful.Reader.Dynamic
-- import Effectful.State.Static.Local
-- import Web.Hyperbole
-- import Web.Hyperbole.Page
--
--
-- main = do
--   run 3000 $ do
--     liveApp (basicDocument "Example") (runReader @Int 5 $ page simplePage)
--
--
-- simplePage :: (Hyperbole :> es, IOE :> es, Reader Int :> es) => Page es '[MainView, Status]
-- simplePage = load $ do
--   liftIO $ putStrLn "MAIN LOAD"
--   pure $ col (pad 20) $ do
--     el bold "My Page"
--     hyper MainView $ do
--       row (gap 10) $ do
--         button GoBegin (border 1) "Start"
--
--
-- -- MAIN ----------------------------------------
--
-- data MainView = MainView
--   deriving (Show, Read, ViewId)
--
--
-- data MainAction
--   = GoBegin
--   | GoMid
--   | GoEnd
--   deriving (Show, Read, ViewAction)
--
--
-- instance HyperView MainView where
--   type Action MainView = MainAction
--   type Require MainView = '[Status]
--
--
-- instance (Reader Int :> es) => HandleView MainView es where
--   handle :: (Hyperbole :> es) => MainView -> MainAction -> Eff es (View MainView ())
--   handle _ action =
--     case action of
--       GoBegin -> do
--         n <- ask @Int
--         pure $ do
--           el_ $ text $ pack $ show n
--           beginStep
--       GoMid -> pure middleStep
--       GoEnd -> pure endStep
--
--
-- beginStep :: View MainView ()
-- beginStep = do
--   el_ "BEGIN"
--   button GoMid (border 1) " Mid"
--
--
-- middleStep :: View MainView ()
-- middleStep = do
--   el_ "MIDDLE: running"
--   button GoBegin (border 1) "Back"
--   hyper Status $ statusView 0
--
--
-- endStep :: View MainView ()
-- endStep = do
--   el_ "END"
--   button GoMid (border 1) "Back"
--
--
-- -- Status ---------------------------------------
--
-- data Status = Status deriving (Show, Read, ViewId)
-- data CheckStatus
--   = CheckStatus Int
--   deriving (Show, Read, ViewAction)
--
--
-- instance HyperView Status where
--   type Action Status = CheckStatus
--   type Require Status = '[MainView]
--
--
-- instance HandleView Status es where
--   handle _ = \case
--     CheckStatus n ->
--       if n >= 5
--         then pure lazyEnd
--         else pure $ statusView (n + 1)
--
--
-- statusView :: Int -> View Status ()
-- statusView n = do
--   onLoad (CheckStatus n) 1000 $ do
--     el_ $ text $ "Checking Status" <> pack (show n)
--
--
-- lazyEnd :: View Status ()
-- lazyEnd = do
--   el_ "Lazy End"
--   hyper MainView $ do
--     button GoEnd (border 1) "Go End"
--
--
