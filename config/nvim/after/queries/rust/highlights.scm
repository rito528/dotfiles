; Make derive targets stand out instead of falling back to plain identifiers.
(attribute
  (identifier) @_attribute_name
  arguments: (token_tree
    [
      (identifier) @type
      (type_identifier) @type
      (scoped_identifier
        name: (identifier) @type)
      (scoped_type_identifier
        name: (type_identifier) @type)
    ])
  (#eq? @_attribute_name "derive"))
