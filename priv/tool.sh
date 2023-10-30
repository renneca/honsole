#!/usr/bin/env zsh

make=dev

make-all () {
    now=$( timestamp )
    rev=$( code-cats | revision )
    make-clean
    make-outs
    make-macros
    make-webkit
    make-app
}

make-clean () {
    rm    -rf ./outs
}

make-outs () {
    mkdir -p  ./outs
}

make-macros () {
    swiftc \
    -g \
        ./impl/honsole-public.swift \
        ./priv/honsole-macros.swift \
    -o  ./outs/honsole-macros
}

make-webkit () {
    make-revision
    code-list echo | xargs \
    swiftc \
    -load-plugin-executable \
        ./outs/honsole-macros'#HonsoleMacros' \
    -g \
    -I  . \
        $* \
        ./outs/honsole-abouts.swift \
    -o  ./outs/honsole-webkit
}

make-revision () {
    make-revision-details \
    >   ./outs/honsole-abouts.swift
}

make-revision-details () {
    line 'let HONSOLE   = "%s"' $honsole
    line 'let H5AGENT   = "%s"' $h5agent
    line 'let VERSION   = "%s"' $version
    line 'let TIMESTAMP = "%s"' $now
    line 'let REVISION  = "%s"' $rev
    line 'let REV ='
    line '['
    code-list make-revision-term
    line ']'
}

make-revision-term () {
    file=$( basename $1 .swift )
    file=${file/honsole-/}
    code=$( revision $1 )
    code=$( hex2col $code )
    misc='%4s( "%s", "%s" ),'
    line $misc '  ' $file $code
}

make-app () {
    make-app-package         ./honsole.app
    make-app-info-plist      ./honsole.app/Contents/Info.plist
    cp ./outs/honsole-webkit ./honsole.app/Contents/MacOS/honsole-webkit
    ex=./outs/honsole-webkit.entitlements
    make-app-entitlements $ex
    code-sign \
        --entitlements $ex \
        -o runtime \
        ./honsole.app
}

make-app-package () {
    rm    -rf           $1
    mkdir -p            $1/Contents/MacOS
    printf 'APPL????' > $1/Contents/PkgInfo
}

make-app-info-plist () {
    plist-create $1
    plist-insert $1 CFBundleIdentifier            -string $product
    plist-insert $1 CFBundleExecutable            -string  honsole-webkit
    plist-insert $1 CFBundleName                  -string  honsole
    plist-insert $1 CFBundleVersion               -string $version/$rev
    plist-insert $1 CFBundlePackageType           -string  APPL
    plist-insert $1 CFBundleSupportedPlatforms    -array
    plist-insert $1 CFBundleSupportedPlatforms    -string  MacOSX -append
    plist-insert $1 CFBundleDevelopmentRegion     -string  en
    plist-insert $1 CFBundleInfoDictionaryVersion -string  6.0
    plist-insert $1 LSApplicationCategoryType     -string  public.app-category.developer-tools
}

make-app-entitlements () {
    plist-create $1
    plist-enable $1 com.apple.security.app-sandbox
    plist-enable $1 com.apple.security.cs.allow-jit
    plist-enable $1 com.apple.security.network.client
}

plist-create () {
    plutil -create xml1 $1
}
plist-insert () {
    plutil -insert ${2//\./\\.} $3 $4 $5 $6 $1
}
plist-enable () {
    plist-insert $1 $2 -bool true
}

code-cats () {
    code-list code-file-cats
}

code-file-cats () {
    printf "\n# +%08x+ #\n" $( printf '%s' $1 | code-file-size )
    printf "%s" $1
    printf "\n# +%08x+ #\n" $( code-file-size $1 )
    cat $1
}

code-file-size () {
    code-file-size-details $( wc -c $* )
}
code-file-size-details () {
    printf '%s' $1
}

revision () {
    ./priv/private-keccak --shake128 --hex $* | tr '[:lower:]' '[:upper:]' | head -c 32
}

timestamp () {
    format='+%Y-%m-%d'
    [[ release = $make ]] ||
    format="$format %H:%M:%S %z"
    date $format
}

code-sign () {
    id=sign
    ts=timestamp
    codesign \
    --$id $( cat ./sign/id.txt ) \
    --$ts=$( cat ./sign/ts.txt ) \
    --generate-entitlement-der \
    $*
}

spec-version () {
    spec-val $( spec-get 3 1 )
}

spec-get () {
    head -n $1 ./spec/honsole-protocol.yaml |
    tail -n $2
}

spec-val () {
    printf '%s' $2
}

hex2col () {
    code="F9"$1"9F"
    size=${#code}
    for (( i = 0; i < size; i+=2 ))
    do
        [ 2 = $(( i % 8 )) ] &&
        printf ' '
        printf '\\u{28%s}' $( hH 0x${code:$i:2} )
    done
}

hH () {
    printf '%02x' $((
        ( ( ( $1 >> 4 ) & 7 ) << 0 ) |
        ( ( ( $1 >> 0 ) & 7 ) << 3 ) |
        ( ( ( $1 >> 7 ) & 1 ) << 6 ) |
        ( ( ( $1 >> 3 ) & 1 ) << 7 )
    ))
}

line () {
    [[ -z $1 ]] ||
    printf $*
    printf "\n"
}

code-list () {
    $* ./impl/honsole-public.swift
    $* ./impl/honsole-detail.swift
    $* ./impl/honsole-webkit.swift
    $* ./impl/honsole-bundle.swift
}

bundle-prefix () {
    cat ./sign/bundle-prefix.txt
}
