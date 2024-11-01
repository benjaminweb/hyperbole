module Web.Hyperbole.HyperView where

import Data.Text (Text, pack)
import Data.Text qualified as T
import Web.Hyperbole.Handler.TypeList (HyperViewHandled)
import Web.Hyperbole.HyperView.Class
import Web.Hyperbole.Route (Route (..), routeUrl)
import Web.View


toActionInput :: (ViewAction a) => (Text -> a) -> Text
toActionInput con =
  -- remove the ' ""' at the end of the constructor
  T.dropEnd 3 $ toAction $ con ""


{- | Embed HyperViews into the page, or nest them into other views

@
myPage :: ('Hyperbole' :> es) => 'Page' es 'Response'
myPage = do
  'handle' messages
  'load' $ do
    pure $ do
      'el_' "My Page"
      'hyper' (Message 1) $ messageView "Hello World"
      'hyper' (Message 2) $ do
        messageView "Another Message"
        'hyper' OtherView otherView
@

Views can only trigger actions that match their HyperView

@
messageView :: Text -> View Message ()
messageView m = do
  el_ (text m)
  button (Louder m) \"Louder\"

otherView :: View OtherView ()
otherView = do
  -- Type Error!
  button (Louder \"Hi\") id \"Louder\"
@
-}

-- TODO: if I'm going to limit it, it's going to happen here
-- AND all their children have to be there
-- , All (Elem (Require ctx)) (Require id)
hyper
  :: forall id ctx
   . (HyperViewHandled id ctx)
  => id
  -> View id ()
  -> View ctx ()
hyper = hyperUnsafe


hyperUnsafe :: (ViewId id) => id -> View id () -> View ctx ()
hyperUnsafe vid vw = do
  el (att "id" (toViewId vid) . flexCol) $
    addContext vid vw


{- | \<button\> HTML tag which sends the action when pressed

> button SomeAction (border 1) "Click Me"
-}
button :: (HyperView id) => Action id -> Mod -> View id () -> View id ()
button a f cd = do
  c <- context
  tag "button" (att "data-on-click" (toAction a) . dataTarget c . f) cd


{- | Send the action after N milliseconds. Can be used to implement lazy loading or polling

@
pollMessageView :: Text -> 'View' Message ()
pollMessageView m = do
  onLoad LoadMessage 1000 $ do
    'el' 'bold' "Current Message. Reloading in 1s"
    'el_' ('text' m)
@
-}
onLoad :: (HyperView id) => Action id -> DelayMs -> View id () -> View id ()
onLoad a delay initContent = do
  c <- context
  el (att "data-on-load" (toAction a) . att "data-delay" (pack $ show delay) . dataTarget c) initContent


type DelayMs = Int


{- | Give visual feedback when an action is in-flight.

@
myView = do
  onRequest loadingIndicator $ do
    'el_' \"Loaded\"
  where
    loadingIndicator = 'el_' "Loading..."
@
-}
onRequest :: View id () -> View id () -> View id ()
onRequest a b = do
  el (parent "hyp-loading" flexCol . hide) a
  el (parent "hyp-loading" hide . flexCol) b


-- | Internal
dataTarget :: (ViewId a) => a -> Mod
dataTarget = att "data-target" . toViewId


{- | Trigger actions for another view. They will update the view specified

> otherView :: View OtherView ()
> otherView = do
>   el_ "This is not a message view"
>   button OtherAction id "Do Something"
>
>   target (Message 2) $ do
>     el_ "Now we can trigger a MessageAction which will update our Message HyperView, not this one"
>     button ClearMessage id "Clear Message #2"
-}
target :: (HyperView id) => id -> View id () -> View a ()
target = addContext


{- | Type-safe dropdown. Sends (opt -> Action id) when selected. The selection predicate (opt -> Bool) controls which option is selected. See [Example.Contacts](https://github.com/seanhess/hyperbole/blob/main/example/Example/Contacts.hs)

@
data ContactsAction
  = Reload (Maybe Filter)
  | Delete Int
  deriving (Generic, Param)

allContactsView :: Maybe Filter -> View Contacts ()
allContactsView fil = do
  row (gap 10) $ do
    el (pad 10) "Filter: "
    dropdown Reload (== fil) id $ do
      option Nothing ""
      option (Just Active) "Active!"
      option (Just Inactive) \"Inactive\"
  ...
@
-}
dropdown
  :: (HyperView id)
  => (opt -> Action id)
  -> (opt -> Bool) -- check if selec
  -> Mod
  -> View (Option opt id (Action id)) ()
  -> View id ()
dropdown act isSel f options = do
  c <- context
  tag "select" (att "data-on-change" "" . dataTarget c . f) $ do
    addContext (Option act isSel) options


-- | An option for a 'dropdown'. First argument is passed to (opt -> Action id) in the 'dropdown', and to the selected predicate
option
  :: (HyperView id, Eq opt)
  => opt
  -> View (Option opt id (Action id)) ()
  -> View (Option opt id (Action id)) ()
option opt cnt = do
  os <- context
  tag "option" (att "value" (toAction (os.toAction opt)) . selected (os.selected opt)) cnt


-- | sets selected = true if the 'dropdown' predicate returns True
selected :: Bool -> Mod
selected b = if b then att "selected" "true" else id


-- | The view context for an 'option'
data Option opt id action = Option
  { toAction :: opt -> action
  , selected :: opt -> Bool
  }


-- | A live search field
search :: (HyperView id) => (Text -> Action id) -> DelayMs -> Mod -> View id ()
search onInput delay f = do
  c <- context
  tag "input" (att "data-on-input" (toActionInput onInput) . att "data-delay" (pack $ show delay) . dataTarget c . f) none


{- | A hyperlink to another route

>>> route (User 100) id "View User"
<a href="/user/100">View User</a>
-}
route :: (Route a) => a -> Mod -> View c () -> View c ()
route r = link (routeUrl r)
