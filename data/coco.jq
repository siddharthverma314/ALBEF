# construct mapping from image_id to image path
(
  [
    .images[]
    | {key: (.id | tostring), value: (.file_name | "\($basedir)/\(.)")}
  ] | from_entries
) as $paths
  | .annotations | map({image: $paths[.image_id | tostring], caption})
