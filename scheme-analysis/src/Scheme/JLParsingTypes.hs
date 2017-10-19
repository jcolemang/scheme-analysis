
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Scheme.JLParsingTypes
  ( modify', modify
  , getLabel
  , initialState
  , BoundValue (..)
  , JLTree (..)
  , ParseState ( ParseState, localEnv, globalEnv )
  , JLSyntax (..)
  , JLParseError (..)
  , ParseMonad (..)
  )
where

import Scheme.Types

import Control.Monad.State
import Control.Monad.Except
import Control.Monad.Identity

-- | Lexing sort of things

data JLTree
  = JLVal Constant SourcePos
  | JLId String SourcePos
  | JLSList [JLTree] SourcePos
  deriving (Show)

data BoundValue
  = BVal
  | BSyntax JLSyntax
  | EmptySlot
  deriving ( Show )

newtype ParseMonad a
  = ParseMonad
  { runParser :: ExceptT JLParseError (StateT ParseState Identity) a
  } deriving ( Functor, Applicative, Monad,
               MonadState ParseState, MonadError JLParseError )

data ParseState
  = ParseState
  { localEnv :: LocalEnvironment BoundValue
  , globalEnv :: GlobalEnvironment BoundValue
  , labelNum :: Int
  } deriving (Show)

instance Environment ParseMonad BoundValue where
  getLocalEnv = localEnv <$> get
  getGlobalEnv = globalEnv <$> get
  putLocalEnv l = modify $ \s -> s { localEnv = l }
  putGlobalEnv g = modify $ \s -> s { globalEnv = g }

initialState :: GlobalEnvironment BoundValue -> ParseState
initialState g =
  ParseState
  { localEnv = createEmptyEnv
  , globalEnv = g
  , labelNum = 0
  }

getLabel :: ParseMonad Int
getLabel = do
  l <- labelNum <$> get
  modify $ \s -> s { labelNum = l + 1 }
  return l

data JLParseError
  = JLParseError SourcePos
  | JLInvalidSyntax String SourcePos
  deriving (Show, Eq)

-- | Formal Syntax

data JLSyntax
  = BuiltIn String (JLTree -> ParseMonad Form)

instance Show JLSyntax where
  show (BuiltIn n _) = "#< " ++ n ++ " >"
