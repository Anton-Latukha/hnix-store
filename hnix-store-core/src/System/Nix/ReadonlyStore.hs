{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}

module System.Nix.ReadonlyStore where


import           Data.ByteString                ( ByteString )
import qualified Data.ByteString               as BS
import qualified Data.Text                     as T
import qualified Data.HashSet                  as HS
import           Data.Text.Encoding
import           System.Nix.Hash
import           System.Nix.StorePath


makeStorePath
  :: forall hashAlgo
   . (NamedAlgo hashAlgo)
  => FilePath
  -> ByteString
  -> Digest hashAlgo
  -> StorePathName
  -> StorePath
makeStorePath fp ty h nm = StorePath storeHash nm fp
 where
  storeHash = hash s

  s =
    BS.intercalate ":" $
      ty:fmap encodeUtf8
        [ algoName @hashAlgo
        , encodeInBase Base16 h
        , T.pack fp
        , unStorePathName nm
        ]

makeTextPath
  :: FilePath -> StorePathName -> Digest 'SHA256 -> StorePathSet -> StorePath
makeTextPath fp nm h refs = makeStorePath fp ty h nm
 where
  ty =
    BS.intercalate ":" ("text" : map storePathToRawFilePath (HS.toList refs))

makeFixedOutputPath
  :: forall hashAlgo
   . (ValidAlgo hashAlgo, NamedAlgo hashAlgo)
  => FilePath
  -> Bool
  -> Digest hashAlgo
  -> StorePathName
  -> StorePath
makeFixedOutputPath fp recursive h =
  if recursive && (algoName @hashAlgo) == "sha256"
    then makeStorePath fp "source" h
    else makeStorePath fp "output:out" h'
 where
  h' =
    hash @ 'SHA256
      $  "fixed:out:"
      <> encodeUtf8 (algoName @hashAlgo)
      <> (if recursive then ":r:" else ":")
      <> encodeUtf8 (encodeInBase Base16 h)
      <> ":"

computeStorePathForText
  :: FilePath -> StorePathName -> ByteString -> (StorePathSet -> StorePath)
computeStorePathForText fp nm = makeTextPath fp nm . hash
