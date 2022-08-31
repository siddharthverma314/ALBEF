split("\n") | [
    .[]
    | select(. != "")
    | split("\t")
    | {image: "\($basedir)/\(.[0])", caption: .[3]}
]
