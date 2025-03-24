#!/bin/sh

# Copy the default.csv file directly to the app bundle
cp "${SRCROOT}/WhereIBeen/Resources/default.csv" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/"

echo "Copied default.csv to app bundle" 