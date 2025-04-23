function cdg --description '{CD back to the root of the current git project}'
    cd $(git rev-parse --show-toplevel)
end
