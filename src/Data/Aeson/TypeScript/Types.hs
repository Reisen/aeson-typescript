{-# LANGUAGE QuasiQuotes, OverloadedStrings, TemplateHaskell, RecordWildCards, ScopedTypeVariables, ExistentialQuantification, PolyKinds #-}

module Data.Aeson.TypeScript.Types where

import qualified Data.Aeson as A
import qualified Data.Aeson.TH as A
import Data.Data
import Data.String

-- | The typeclass that defines how a type is turned into TypeScript.
--
-- The 'getTypeScriptDeclarations' method describes the top-level declarations that are needed for a type,
-- while 'getTypeScriptType' describes how references to the type should be translated. The 'getTypeScriptOptional'
-- method exists purely so that 'Maybe' types can be encoded with a question mark.
--
--  Instances for common types are built-in and are usually very simple; for example,
--
-- @
-- instance TypeScript Bool where
--   getTypeScriptType _ = "boolean"
-- @
--
-- Most of the time you should not need to write instances by hand; in fact, the 'TSDeclaration'
-- constructors are deliberately opaque. However, you may occasionally need to specify the type of something.
-- For example, since 'UTCTime' is encoded to a JSON string and is not built-in to this library:
--
-- @
-- import Data.Time.Clock (UTCTime)
--
-- instance TypeScript UTCTime where
--   getTypeScriptType _ = "string"
-- @
--
-- If you need to write a definition for a higher-order type, it may depend on a type parameter. For example,
-- a 'Set' is encoded to a JSON list of the underlying type:
--
-- @
-- instance (TypeScript a) => TypeScript (Set a) where
--   getTypeScriptType _ = getTypeScriptType (Proxy :: Proxy a) <> "[]";
-- @
class TypeScript a where
  getTypeScriptDeclarations :: Proxy a -> [TSDeclaration]
  -- ^ Get the declaration(s) needed for this type.
  getTypeScriptDeclarations _ = []

  getTypeScriptType :: Proxy a -> String
  -- ^ Get the type as a string.

  getTypeScriptOptional :: Proxy a -> Bool
  -- ^ Get a flag representing whether this type is optional.
  getTypeScriptOptional _ = False

data TSDeclaration = TSInterfaceDeclaration { interfaceName :: String
                                            , interfaceGenericVariables :: [String]
                                            , interfaceMembers :: [TSField] }
                   | TSTypeAlternatives { typeName :: String
                                        , typeGenericVariables :: [String]
                                        , alternativeTypes :: [String]}
  deriving (Show, Eq)

data TSField = TSField { fieldOptional :: Bool
                       , fieldName :: String
                       , fieldType :: String } deriving (Show, Eq)

newtype TSString a = TSString { unpackTSString :: String } deriving Show

instance IsString (TSString a) where
  fromString = TSString

-- * Formatting options

data FormattingOptions = FormattingOptions
  { numIndentSpaces       :: Int
  -- ^ How many spaces to indent TypeScript blocks
  , interfaceNameModifier :: String -> String
  -- ^ How to modify an output interface name
  , typeNameModifier :: String -> String
  -- ^ How to modify an output type name
  }

defaultFormattingOptions = FormattingOptions
  { numIndentSpaces = 2
  , interfaceNameModifier = id
  , typeNameModifier = id
  }

-- | Convenience typeclass class you can use to "attach" a set of Aeson encoding options to a type.
class HasJSONOptions a where
  getJSONOptions :: (Proxy a) -> A.Options
