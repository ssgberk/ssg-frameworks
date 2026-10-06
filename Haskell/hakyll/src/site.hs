{-# LANGUAGE OverloadedStrings #-}
import Hakyll

postCtx :: Context String
postCtx =
    dateField "date" "%Y-%m-%d"
        <> dateField "datetime" "%Y-%m-%dT%H:%M:%SZ"
        <> defaultContext

main :: IO ()
main = hakyll $ do
    match "assets/*" $ do
        route idRoute
        compile copyFileCompiler

    match "templates/*" $ compile templateBodyCompiler

    match "posts/*" $ do
        route $ setExtension "html"
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/post.html" postCtx
                >>= loadAndApplyTemplate "templates/default.html" postCtx

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts)
                        <> defaultContext
            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
