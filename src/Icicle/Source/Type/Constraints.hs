{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternGuards #-}
module Icicle.Source.Type.Constraints (
  ) where

{-
import                  Icicle.Source.Type.Base

import qualified        Data.Map as Map

import P


data DataConstraint
 = Subtype BaseType BaseType
 deriving (Eq, Ord, Show)

data DataConstraintError
 = DataConstraintErrorTodo
 deriving (Eq, Ord, Show)

data Subst
 = Subst (Map.Map TypeVarIndex BaseType)

unifyData   :: [DataConstraint]
            -> Either DataConstraintError Subst
unifyData _
 -- TODO
 = return $ Subst Map.empty

substData :: Subst -> BaseType -> BaseType
substData (Subst s) tt
 = go tt
 where
  go t
   = case t of
      IntT      -> t
      DoubleT   -> t
      UnitT     -> t
      BoolT     -> t
      DateTimeT -> t
      ArrayT a  -> ArrayT  (go a)
      MapT a b  -> MapT    (go a) (go b)
      OptionT a -> OptionT (go a)
      PairT a b -> PairT   (go a) (go b)
      StructT st-> StructT $ Map.map go st)
      StringT   -> t


data ModeConstraint
 = Applies UniverseType
 | Submode UniverseType UniverseType
 deriving (Eq, Ord, Show)

-}
