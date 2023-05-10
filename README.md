# Check EDNS padding features of Encrypted DNS resolvers
Checking public resolvers' compliance with EDNS padding advised by RFC 8467 

# Get this repo
```
git clone https://github.com/cslev/edns_padding
```

## Checkout the submodule
The source tree contains a submodule that has the encrypted DNS resolvers' data as JSON. Let's check that repo out as well.
```
cd edns_padding
git submodule update --init --recursive
```

