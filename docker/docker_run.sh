docker run \
    -d \
    --name balance_of_power \
    -p 3000:3000 \
    #-v $HOME/bop-data:/var/lib/mongodb \  # Mount this for persistent data
    bop
