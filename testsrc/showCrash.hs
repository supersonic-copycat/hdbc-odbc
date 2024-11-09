module Main where

import Control.Monad (forM_)
import Database.HDBC
import Database.HDBC.ODBC

data DBProvider = SQLite | MariaDB deriving (Show, Eq)

queryPrepareWork :: DBProvider -> String
queryPrepareWork SQLite = "DROP TABLE IF EXISTS main.TestTable; CREATE TABLE main.TestTable (F1 VARCHAR(20) NOT NULL, F2 INT);"
queryPrepareWork MariaDB = "CREATE OR REPLACE TABLE main.TestTable (F1 TEXT NOT NULL, F2 INTEGER);"

querySendDataPredefined :: String
querySendDataPredefined =
  "INSERT INTO main.TestTable (F1, F2) VALUES ('0', 0), ('1', 1), ('2', 2), ('3', 3), ('4', 4), ('5', 5), \
  \ ('6', 6), ('7', 7), ('8', 8), ('9', 9);"

querySendData :: String
querySendData = "INSERT INTO main.TestTable (F1, F2) VALUES (?, ?);"

queryGetBack :: String
queryGetBack = "SELECT COUNT(*) FROM main.TestTable;"

getConn :: DBProvider -> IO ConnWrapper
getConn SQLite = ConnWrapper <$> connectODBC "DSN=hdbctest_sqlite;"
getConn MariaDB = ConnWrapper <$> connectODBC "DSN=hdbctest_maria;"

countDefault :: Integer
countDefault = 5000

testNonParametrized :: Integer -> DBProvider -> IO ()
testNonParametrized count provider = do
  conn <- getConn provider
  -- prepare table
  withTransaction conn $
    \conn -> do
      () <- runRaw conn $ queryPrepareWork provider
      stmt <- prepare conn querySendDataPredefined
      --print "prepared statement"
      forM_ [1 .. (count `div` 10)] $
        \_ -> do
          executeRaw stmt
      res <- quickQuery conn queryGetBack []
      print res

testParametrized :: Integer -> DBProvider -> IO ()
testParametrized count provider = do
  conn <- getConn provider
  withTransaction conn $
    \conn -> do
      () <- runRaw conn $ queryPrepareWork provider
      stmt <- prepare conn querySendData
      -- print "prepared stmt"
      -- send each number to DB
      forM_ [0 .. count - 1] $
        \i -> execute stmt [SqlString $ show i, SqlInteger $ toInteger i]
      -- print $ "executed statemet for " <> show i
      res <- quickQuery conn queryGetBack []
      print res

testParametrizedQuick :: Integer -> DBProvider -> IO ()
testParametrizedQuick count provider = do
  -- prep data and send an once (laziness??)
  let vals = fmap (\x -> [SqlString $ show x, SqlInteger x]) [0 .. count - 1]
  conn <- getConn provider
  withTransaction conn $
    \conn -> do
      () <- runRaw conn $ queryPrepareWork provider
      stmt <- prepare conn querySendData
      executeMany stmt vals
      res <- quickQuery conn queryGetBack []
      print res

main :: IO ()
main = do
  let provider = MariaDB
      --count = countDefault
      count = 1000
  putStrLn "Try query without parameters"
  testNonParametrized count provider
  putStrLn "Done test without parameters"
  putStrLn "Try query with parameters (simple)"
  testParametrized count provider
  putStrLn "Done test with parameters (simple)"
  putStrLn "Try query with parameters (quicker)"
  testParametrizedQuick count provider
  putStrLn "Done test with parameters (quicker)"
