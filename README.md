# Haskupcake

Haskupcake is a [Haskell](https://www.haskell.org/) library to build and send requests to the [PIC-SURE](http://bd2k-picsure.hms.harvard.edu/) API.

it's name is strongly influenced by the [Rcupcake](https://github.com/hms-dbmi/Rcupcake) library, since they both accomplish the same goal.

## Installation

The use of [stack](https://docs.haskellstack.org/en/stable/install_and_upgrade/) is recommended.


### Use the library

#### Clone the repo

```sh
git clone https://github.com/mikaunix/haskupcake
```

To use the library in your own projects, add the path to the directory containing the cloned haskupcake repo to your `stack.yaml`:

```
packages:
- .
- /path/to/haskupcake
```
#### Let stack do it for you

Instead of manually cloning the repo, you can [specify the github repo with a commit](https://github.com/commercialhaskell/stack/blob/master/doc/yaml_configuration.md#git-and-mercurial-repos) in the `stack.yaml` file:

```
extra-deps:
- git: https://github.com/mikaunix/haskupcake.git
  commit: 876c2f3a2944fd3f06ff612a911d6a0d2922c748
```

#### Add haskupcake to the dependencies

Finally add the library as a dependency of your project in your `package.yaml` file:

```
executables:
  foo-exe:
    dependencies:
    - foo
    - haskupcake
```

## Usage

Here are the main modules exposed by haskupcake:

```haskell
import PicSure.Config
import PicSure.Resource
import PicSure.Query
import PicSure.Security
import PicSure.Types
```

### YAML configuration file

This is a simple [YAML](https://en.wikipedia.org/wiki/YAML) file, containing an object that needs to have a `domain` and a `token` attribute:

```yaml
domain: https://your.domain.name
debug: false
token: yourSecretToken
```

It needs to be loaded with `readConfig` from the `PicSure.Config` module, which will return a `Config` object to use with your queries.  
The `debug` attribute is optional, and gives a more detailled output.  
`token` is required (api key authentication is not supported)

### State monad

The configuration file is passed around with the help of the [State Monad](https://wiki.haskell.org/All_About_Monads#The_State_monad).
Therefore you will need to initiate your calls with `runStateT` and lift your IO operations with `liftIO`.

You may use the helper `withConfig` function, that takes the path to the configuration file, some action in the readerT monad, and returns an IO operation.

```haskell
withConfig :: FilePath -> PicSureM a -> IO a
withConfig s f = readConfig s >>=
                 genPicState  >>=
                 (fst <$>) . runStateT f

-- usage example:
-- using the config file "config.yaml", list the available resources
main = withConfig "config.yaml" $ lsPath' "/"


-- using the config file "config.yaml", query the variable "AGE" using the alias name "Age"
-- and saves the resulting table as "test.csv"
main = withConfig "config.yaml" $ simpleQuery ([("Age","AGE")]) "test.csv"
```

Don't forget to use `liftIO` if you want to perform IO operations inside the Reader monad:

```haskell
main = do
  l <- withConfig "config.yaml" $ do
    paths <- lsPath' ""
    liftIO $ print paths
    lsPath' $ head paths
  print l
```

This would print the paths directly under the root directory, and return the result of listing the first of those paths. This is not a useful thing to do, but at least it clearly shows how to insert IO.

### Requesting paths

As we saw earlier, it's possible to list the direct children of a given path quite easily. `lsPath` takes one more parameter than `lsPath'`, a boolean value to return only the names of the nodes instead of the full path:

```haskell
lsPath :: Bool -> String -> ReaderT Config IO [String]
lsPath relative path = do (...)

lsPath' = lsPath False
```

It's also possible to search for a path, if you know the name of what you're looking for but not the absolute path leading to it:

```haskell
-- |search a specific <node>, starting at the absolute path <from>
searchPath :: String -> String -> PicSureM String

-- |search in all the available resources
searchPath' :: String -> PicSureM String
searchPath' node = searchPath node "/"
```

This will perform a breadth-first search on all the available paths and return the first one with the same name as the one you provided, or nothing if it didn't find anything.  
Use it with a bit of patience at hand, because one HTTP request has to be performed at each step, and it can take a long time to complete.

Note that you can vastly improve the speed of the search by providing a part of the path instead of just the variable name. It will also help making sure that the first occurence found by the algorithm is the one you are looking for (variable names may not be unique)

```haskell

```

### Querying data

the `query` function takes a list of `Variable`, a list of `Where` clauses, and builds a JSON body out of them and sends it to PIC-SURE's runQuery. Thoses types are defined in the `PicSure.Type` module.

You'll get back a query ID, which you can use with `resultStatus`, `resultAvailableformats`, `resultFetch` and `resultDownload`.

`ResultFetch` returns a `Either Text.Parsec.Error.ParseError [[String]]`. it uses [Data.CSV](https://hackage.haskell.org/package/MissingH-1.4.0.1/docs/Data-CSV.html) to parse the response.  
Be careful because all the data will sit in memory after this call.

`resultDownload`reads the response's body and writes it to a file, chunk by chunk. This will run in constant space, so you're only limited by your disk space, not your RAM.
