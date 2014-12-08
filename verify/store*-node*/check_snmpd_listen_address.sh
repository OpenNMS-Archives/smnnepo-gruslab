ss -lnpu | grep -E '192\.168\.0\.[0-9]+:161' || ( echo "Not listening" ; false )
