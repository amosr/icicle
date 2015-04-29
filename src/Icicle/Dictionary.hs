{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Icicle.Dictionary (
    Dictionary (..)
  , Definition (..)
  , Virtual (..)
  , demographics
  ) where

import           Icicle.Data

import qualified Icicle.Core.Base            as N -- N for name
import qualified Icicle.Core.Type            as T
import qualified Icicle.Core.Exp             as X
import qualified Icicle.Core.Stream          as S
import qualified Icicle.Core.Reduce          as R
import qualified Icicle.Core.Program.Program as P

import           P

import           Data.Text


data Dictionary =
  Dictionary [(Attribute, Definition)]
  deriving (Eq, Show)


data Definition =
    ConcreteDefinition Encoding
  | VirtualDefinition  Virtual
  deriving (Eq, Show)


data Virtual =
  Virtual {
      -- | Name of concrete attribute used as input
      concrete :: Attribute
    , program  :: P.Program Text
    } deriving (Eq, Show)



-- | Example demographics dictionary
-- Hard-coded for now
demographics :: Dictionary
demographics =
 Dictionary 
 [ (Attribute "gender",             ConcreteDefinition StringEncoding)
 , (Attribute "age",                ConcreteDefinition IntEncoding)
 , (Attribute "state_of_residence", ConcreteDefinition StringEncoding)
 , (Attribute "salary",             ConcreteDefinition IntEncoding)
 
  -- Useless virtual features
 , (Attribute "sum_salary",         VirtualDefinition
                                  $ Virtual (Attribute "salary") program_sum)
 , (Attribute "num_salary",         VirtualDefinition
                                  $ Virtual (Attribute "salary") program_count)
 ]


-- | Dead simple sum
program_sum :: P.Program Text
program_sum
 = P.Program
 { P.input      = T.IntT
 , P.precomps   = []
 , P.streams    = [(N.Name "inp", S.Source)]
 , P.reduces    = [(N.Name "red", fold_sum (N.Name "inp"))]
 , P.postcomps  = []
 , P.returns    = X.XVar (N.Name "red")
 }

fold_sum :: N.Name Text -> R.Reduce Text
fold_sum inp
 = R.RFold t t
        ( X.XLam a t
        $ X.XLam b t
        $ add `X.XApp` X.XVar a `X.XApp` X.XVar b)
        (X.XPrim $ X.PrimConst $ X.PrimConstInt 0) inp
 where
  a = N.Name "a"
  b = N.Name "b"
  t = T.IntT
  add = X.XPrim $ X.PrimArith $ X.PrimArithPlus


-- | Count
program_count :: P.Program Text
program_count
 = P.Program
 { P.input      = T.IntT
 , P.precomps   = []
 , P.streams    = [(N.Name "inp", S.Source)
                  ,(N.Name "ones", S.STrans (S.SMap T.IntT T.IntT) const1 (N.Name "inp"))]
 , P.reduces    = [(N.Name "count", fold_sum (N.Name "ones"))]
 , P.postcomps  = []
 , P.returns    = X.XVar (N.Name "count")
 }
 where
  const1 = X.XLam (N.Name "ignored") T.IntT
         $ X.XPrim $ X.PrimConst $ X.PrimConstInt 1

