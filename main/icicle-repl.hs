{-# LANGUAGE ViewPatterns #-}

import           Control.Monad
import           Data.Text                   (Text)
import qualified Data.Text                   as T
import qualified System.Console.Haskeline    as HL
import qualified Text.PrettyPrint.Leijen     as PP

import           Icicle
import qualified Icicle.Core.Program.Program as CP
import qualified Icicle.Repl                 as SR
import qualified Icicle.Source.Parser        as SP
import           System.Environment

main :: IO ()
main = runRepl

runRepl :: IO ()
runRepl
  = do putStrLn "icicle-repl"
       HL.runInputT HL.defaultSettings $ loop defaultState
  where
    loop :: ReplState -> HL.InputT IO ()
    loop state
      = do line <- HL.getInputLine "> "
           case line of
             Nothing      -> loop state
             Just ":quit" -> return ()
             Just ":q"    -> return ()
             Just str     -> handleLine state str >>= loop

--------------------------------------------------------------------------------

data ReplState
   = ReplState
   { dataFeat :: Maybe String
   , hasType  :: Bool
   , hasCore  :: Bool
   , hasEval  :: Bool }

-- | Settable REPL states
data Set
   = ShowType
   | ShowCore
   | ShowEval

-- | REPL commands
data Command
   = CommandBlank
   | CommandSet  Set
   | CommandLoad FilePath

defaultState :: ReplState
defaultState
  = ReplState Nothing False False False

readCommand :: String -> Maybe Command
readCommand (words -> ss)
  | null ss                    = Just CommandBlank
  | ":set":"show-type":_ <- ss = Just $ CommandSet ShowType
  | ":set":"show-core":_ <- ss = Just $ CommandSet ShowCore
  | ":set":"show-eval":_ <- ss = Just $ CommandSet ShowEval
  | ":load":f:_          <- ss = Just $ CommandLoad f
  | otherwise                  = Nothing

handleLine :: ReplState -> String -> HL.InputT IO ReplState
handleLine state line = case readCommand line of
  Just CommandBlank          -> do
    HL.outputStrLn "please input a command or an Icicle expression"
    return state

  -- Whether to show type of result
  Just (CommandSet ShowType) -> do
    let v = not (hasType state)
    HL.outputStrLn $ concat ["ok, show-type is now ", showFlag v]
    return $ state { hasType = v }

  -- Whether to show core
  Just (CommandSet ShowCore) -> do
    let v = not (hasCore state)
    HL.outputStrLn $ concat ["ok, show-core is now ", showFlag v]
    return $ state { hasCore = v }

  -- Whether to show eval result
  Just (CommandSet ShowEval) -> do
    let v = not (hasEval state)
    HL.outputStrLn $ concat ["ok, show-eval is now ", showFlag v]
    return $ state { hasEval = v }

  Just (CommandLoad fp)      -> do
    HL.outputStrLn "dunno"
    return state

  -- An Icicle expression
  Nothing -> do
    when (hasCore state) $ case showCore (T.pack line) of
        Left  e -> HL.outputStrLn "REPL error:" >> prettyHL e
        Right p -> HL.outputStrLn "Result:" >> prettyHL p
    return state

prettyHL :: PP.Pretty a => a -> HL.InputT IO ()
prettyHL x = HL.outputStrLn $ PP.displayS (PP.renderCompact $ PP.pretty x) ""

showFlag :: Bool -> String
showFlag True  = "on"
showFlag False = "off"

--------------------------------------------------------------------------------

type ProgramV = CP.Program SP.Variable

showCore :: Text -> Either SR.ReplError ProgramV
showCore = SR.sourceParseConvert

