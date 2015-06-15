{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Icicle.Repl (
    ReplError (..)
  , sourceParse
  , sourceCheck
  , sourceConvert
  , sourceParseConvert
  ) where

import qualified        Icicle.Dictionary               as D
import qualified        Icicle.Data                     as D

import qualified        Icicle.Common.Fresh             as Fresh
import qualified        Icicle.Common.Base              as Com
import qualified        Icicle.Common.Type              as Com
import qualified        Icicle.Core.Program.Program     as Core

import qualified        Icicle.Source.Checker.Checker   as SC
import qualified        Icicle.Source.Checker.Error     as SC
import qualified        Icicle.Source.Parser            as SP
import qualified        Icicle.Source.Query             as SQ
import qualified        Icicle.Source.ToCore.ToCore     as STC
import qualified        Icicle.Source.ToCore.Base       as STC
import qualified        Icicle.Source.Type              as ST

import                  P
import                  Data.Either.Combinators

import qualified        Data.Map as Map
import qualified        Data.Text as T


data ReplError
 = ReplErrorParseError SP.ParseError
 | ReplErrorCheckError   (SC.CheckError SP.SourcePos Var)
 | ReplErrorConvertError (STC.ConvertError SP.SourcePos Var)
 deriving (Show)

type Var        = SP.Variable
type QueryTop'  = SQ.QueryTop SP.SourcePos Var
type QueryTop'T = SQ.QueryTop (SP.SourcePos, ST.UniverseType) Var

type Program'   = Core.Program Var

sourceParse :: T.Text -> Either ReplError QueryTop'
sourceParse t
 = mapLeft ReplErrorParseError
 $ SP.parseQueryTop t


sourceCheck :: D.Dictionary -> QueryTop' -> Either ReplError (QueryTop'T, ST.UniverseType)
sourceCheck d q
 = let d' = featureMapOfDictionary d
   in  mapLeft ReplErrorCheckError
     $ SC.checkQT d' q


sourceConvert :: QueryTop'T -> Either ReplError Program'
sourceConvert q
 = mapRight snd
 $ mapLeft ReplErrorConvertError
 $ Fresh.runFreshT (STC.convertQueryTop q) namer
 where
  mkName i = Com.Name $ SP.Variable ("v" <> T.pack (show i))
  namer = Fresh.counterNameState mkName 0


sourceParseConvert :: T.Text -> Either ReplError Program'
sourceParseConvert t
 = do   q <- sourceParse t
        (q',_) <- sourceCheck D.demographics q
        sourceConvert q'


featureMapOfDictionary :: D.Dictionary -> Map.Map Var (Map.Map Var ST.BaseType)
featureMapOfDictionary (D.Dictionary ds)
 = Map.fromList
 $ concatMap go
   ds
 where
  go (D.Attribute attr, D.ConcreteDefinition _enc)
   -- TODO: convert Encoding to feature map
   = [(SP.Variable attr, Map.singleton (SP.Variable "value") Com.IntT)]
  go _
   = []

