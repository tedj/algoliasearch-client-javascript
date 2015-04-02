#!/usr/bin/env bash

# Use this with `npm run build` so that `./node_modules/.bin` are injected into
# the PATH

license="/*! algoliasearch ${PACKAGE_VERSION} | © 2014, 2015 Algolia SAS | github.com/algolia/algoliasearch-client-js */"

echo 'Building algoliasearch-client-js'

bundles=( algoliasearch algoliasearch.angular algoliasearch.jquery )

# The migration layer have two purposes
#   1. For people still using cdn.jsdelivr.net/algoliasearch/latest/..
#     It will detect it and load V2, since V3 is now "latest" and is not backward compatible
#     V2 will either be loaded with document.write or a script DOMElement (when the current script is loaded asynchronously)
#     A warning will be displayed
#   2. If we are loaded as cdn.jsdelivr.net/algoliasearch/3/.., we will export
#     AlgoliaSearch AlgoliaSearchHelper ALgoliaExplainResults, they will throw
#     With a message saying "You updated to V3, but you are using V2 notation"
# The first migration layer is prepended before the V3 build, because of module loaders that
# would not execute the code until the module is required
echo '..Add V2 migration layer'
for bundle in "${bundles[@]}"
do
  # First part of migration layer, "src/migration-layer/script.js"
  ALGOLIA_BUILDNAME="$bundle" browserify src/browser/migration-layer/script.js -s ALGOLIA_MIGRATION_LAYER -p bundle-collapser/plugin -p deumdify -t envify > dist/"$bundle".js
done

echo '..Add browserify bundles'
# cannot use a loop, bundles are different (--standalone)
browserify -p bundle-collapser/plugin src/browser/builds/algoliasearch.js --standalone algoliasearch >> dist/algoliasearch.js
browserify -p bundle-collapser/plugin src/browser/builds/algoliasearch.angular.js >> dist/algoliasearch.angular.js
browserify -p bundle-collapser/plugin src/browser/builds/algoliasearch.jquery.js >> dist/algoliasearch.jquery.js

echo '..Minify'
for bundle in "${bundles[@]}"
do
  ccjs dist/"$bundle".js > dist/"$bundle".min.js
done

echo '..Prepend license'

# We prepend the license to be sure it's always present, no matter the used minifier
# http://www.cyberciti.biz/faq/bash-prepend-text-lines-to-file/
for bundle in "${bundles[@]}"
do
  echo "$license" | cat - dist/"$bundle".js > /tmp/out && mv /tmp/out dist/"$bundle".js
  echo "$license" | cat - dist/"$bundle".min.js > /tmp/out && mv /tmp/out dist/"$bundle".min.js
done

echo '..Gzipped file size'
for bundle in "${bundles[@]}"
do
  echo "${bundle}.js gzipped will weight" $(cat dist/"${bundle}".min.js | gzip -9 | wc -c | pretty-bytes)
done

echo 'Done'
