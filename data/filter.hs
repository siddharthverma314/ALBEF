{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import Codec.Picture (readImage)
import Control.Monad (when)
import qualified Control.Monad.Parallel as PM
import Data.Aeson (FromJSON, ToJSON, decodeFileStrict', encodeFile)
import Data.List (foldl1')
import Data.Map.Strict
import Data.Maybe (catMaybes)
import Data.Text.Lazy (empty, pack)
import GHC.Float (int2Float)
import GHC.Generics
import System.Environment
import System.Exit
import System.ProgressBar
import Text.Printf

data DataPoint = DataPoint
  { image :: !FilePath,
    caption :: !String
  }
  deriving (Generic, Show)

instance FromJSON DataPoint

instance ToJSON DataPoint

readDataPoints :: FilePath -> IO [DataPoint]
readDataPoints file = do
  fs <- decodeFileStrict' file
  case fs of
    Nothing -> error "Unable to parse files"
    Just x -> return x

imageError :: FilePath -> IO (Maybe String)
imageError fp = do
  img <- readImage fp
  return $ case img of
    Left s -> Just s
    Right _ -> Nothing

main = do
  args <- getArgs
  when (length args /= 2) $ do
    putStrLn "Usage: [raw_json] [new_json]"
    exitWith $ ExitFailure (-1)
  let [rawJson, newJson] = args

  putStrLn "Reading data..."
  dps <- readDataPoints rawJson

  putStrLn "Grouping by filepath..."
  let dpMap = fromListWith (++) $ (\dp -> (image dp, [dp])) <$> dps

  putStrLn $ printf "Found %d images" $ length dpMap

  putStrLn "Start filtering..."
  pb <-
    newProgressBar
      ( defStyle
          { stylePostfix =
              Label
                { runLabel =
                    \(Progress c' t' e') _ ->
                      let c = int2Float c'
                          t = int2Float t'
                          e = int2Float e'
                       in pack $ printf "Done: %.2f%%|Error: %.2f%%|Remaining: " (c * 100 / t) (e * 100 / c)
                }
                <> remainingTime renderDuration "...",
            styleWidth = TerminalWidth 40
          }
      )
      10
      (Progress 0 (length dpMap) 0)

  dps <-
    concat
      <$> PM.forM
        (toList dpMap)
        ( \(fp, dps) -> do
            err <- imageError fp
            case err of
              Nothing -> do
                incProgress pb 1
                return dps
              Just err -> do
                updateProgress pb $ \(Progress c t e) -> Progress (c + 1) t (e + 1)
                return []
        )

  putStrLn "Saving..."
  encodeFile newJson dps
